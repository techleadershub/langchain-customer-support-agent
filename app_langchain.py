"""
Customer Support AI - LangChain Tools Version

A simplified Streamlit app using LangChain tools for ticket classification,
response generation, and refund processing.

Based on: support-agent.py architecture
Features: 3 LangChain tools + Supabase integration
"""

import streamlit as st
import os
from datetime import datetime
import random
import pandas as pd
from dotenv import load_dotenv

from langchain_openai import ChatOpenAI
from langchain_core.tools import tool

try:
    from supabase import create_client, Client
    SUPABASE_AVAILABLE = True
except ImportError:
    SUPABASE_AVAILABLE = False
    print("Supabase not available, using PostgreSQL only")

from sqlalchemy import create_engine, text
from config import DB_CONFIG

# Load environment variables
load_dotenv()

# Try Streamlit secrets first, then environment variables
try:
    api_key = st.secrets["OPENAI_API_KEY"]
except:
    api_key = os.getenv("OPENAI_API_KEY")

# Initialize LLM
llm = ChatOpenAI(model="gpt-3.5-turbo", temperature=0.7, api_key=api_key)

# Mock orders database (for demo/learning purposes)
ORDERS = {
    "ORD123": {"amount": 99.99, "item": "Laptop"},
    "ORD456": {"amount": 49.99, "item": "Mouse"},
    "ORD789": {"amount": 149.99, "item": "Monitor"},
    "ORD101": {"amount": 299.99, "item": "Keyboard"},
    "ORD202": {"amount": 199.99, "item": "Webcam"}
}


# ============================================================================
# LANGCHAIN TOOLS
# ============================================================================

@tool
def triage_ticket(ticket_text: str) -> str:
    """Classify support ticket into: refund, technical, billing, or general"""
    
    prompt = f"""Classify this customer support ticket into ONE category.

Categories:
- refund: Returns, damaged items, wrong items, refund requests
- technical: Login issues, bugs, errors, password problems, software issues
- billing: Payment issues, charges, invoices, subscriptions
- general: Other inquiries, questions, feedback

Ticket: {ticket_text}

Respond with ONLY ONE WORD from the categories above."""
    
    response = llm.invoke(prompt)
    category = response.content.strip().lower()
    
    # Validate category
    valid_categories = ["refund", "technical", "billing", "general"]
    if category not in valid_categories:
        return "general"
    
    return category


@tool
def generate_response(ticket_text: str, category: str) -> str:
    """Generate professional customer support response"""
    
    prompt = f"""You are a professional customer support representative. 
Write a helpful, empathetic email response for this {category} support ticket.

Customer ticket: {ticket_text}

Requirements:
- Be friendly and professional
- Acknowledge the customer's concern
- Provide helpful next steps
- Keep it concise (3-4 sentences)
- Use appropriate tone for the issue type

Write the response:"""
    
    response = llm.invoke(prompt)
    return response.content.strip()


@tool
def process_refund_request(ticket_text: str) -> str:
    """Extract order ID from ticket and check refund eligibility"""
    
    # Step 1: Extract order ID using LLM
    extract_prompt = f"""Extract the order ID from this customer message.
Order IDs are in format: ORD followed by numbers (e.g., ORD123, ORD456).

Customer message: {ticket_text}

If you find an order ID, respond with ONLY the order ID (e.g., ORD123).
If no order ID is found, respond with: NONE"""
    
    extract_response = llm.invoke(extract_prompt)
    order_id = extract_response.content.strip().upper()
    
    # Step 2: Check if order ID was found
    if order_id == "NONE" or not order_id.startswith("ORD"):
        return "❌ No order ID found in ticket. Please provide order number (e.g., ORD123)."
    
    # Step 3: Check if order exists in database
    order = ORDERS.get(order_id)
    if not order:
        return f"❌ Order {order_id} not found in system. Please verify order number."
    
    # Step 4: Check eligibility (random for demo/learning purposes)
    is_eligible = random.choice([True, False])
    
    if is_eligible:
        return f"✅ Refund Approved - {order_id}: {order['item']} (${order['amount']:.2f}) will be refunded in 3-5 business days."
    else:
        return f"❌ Refund Denied - {order_id}: {order['item']} (${order['amount']:.2f}) does not meet refund criteria. Please contact support for details."


# ============================================================================
# DATABASE FUNCTIONS
# ============================================================================

def save_to_database(subject, body, category, draft_response):
    """Save classification results to Supabase/PostgreSQL"""
    if not DB_CONFIG["url"]:
        return False
    
    try:
        if DB_CONFIG["type"] == "supabase" and SUPABASE_AVAILABLE:
            # Use Supabase client
            supabase: Client = create_client(DB_CONFIG["url"], DB_CONFIG["key"])
            
            result = supabase.table("tickets").insert({
                "subject": subject,
                "body": body,
                "ai_predicted_category": category,
                "ai_confidence": 0.95,
                "ai_method": "LangChain Tools",
                "draft_response": draft_response,
                "ai_classified_at": datetime.now().isoformat(),
                "status": "processed",
                "user_id": "demo_user"
            }).execute()
            
        else:
            # Use direct PostgreSQL connection
            engine = create_engine(DB_CONFIG["url"])
            
            # Add draft_response column if it doesn't exist
            alter_table_sql = """
            ALTER TABLE tickets 
            ADD COLUMN IF NOT EXISTS draft_response TEXT;
            """
            
            with engine.connect() as conn:
                conn.execute(text(alter_table_sql))
                conn.commit()
                
                # Insert new ticket
                insert_sql = """
                INSERT INTO tickets 
                (subject, body, ai_predicted_category, ai_confidence, ai_method, 
                 draft_response, ai_classified_at, status, user_id)
                VALUES (:subject, :body, :category, :confidence, :method, 
                        :draft_response, CURRENT_TIMESTAMP, :status, :user_id)
                """
                
                conn.execute(text(insert_sql), {
                    "subject": subject,
                    "body": body,
                    "category": category,
                    "confidence": 0.95,
                    "method": "LangChain Tools",
                    "draft_response": draft_response,
                    "status": "processed",
                    "user_id": "demo_user"
                })
                conn.commit()
        
        return True
        
    except Exception as e:
        st.error(f"Database error: {str(e)}")
        return False


def get_recent_classifications():
    """Get recent classifications from database"""
    if not DB_CONFIG["url"]:
        return None
    
    try:
        if DB_CONFIG["type"] == "supabase" and SUPABASE_AVAILABLE:
            supabase: Client = create_client(DB_CONFIG["url"], DB_CONFIG["key"])
            
            response = supabase.table("tickets").select(
                "subject, ai_predicted_category, ai_classified_at"
            ).not_.is_("ai_predicted_category", "null").order(
                "ai_classified_at", desc=True
            ).limit(10).execute()
            
            df = pd.DataFrame(response.data)
            return df
            
        else:
            engine = create_engine(DB_CONFIG["url"])
            
            query = """
            SELECT subject, ai_predicted_category, ai_classified_at
            FROM tickets 
            WHERE ai_predicted_category IS NOT NULL
            ORDER BY ai_classified_at DESC 
            LIMIT 10
            """
            
            df = pd.read_sql(query, engine)
            return df
        
    except Exception as e:
        st.error(f"Database error: {str(e)}")
        return None


def get_total_classifications():
    """Get total count of classifications"""
    if not DB_CONFIG["url"]:
        return 0
    
    try:
        if DB_CONFIG["type"] == "supabase" and SUPABASE_AVAILABLE:
            supabase: Client = create_client(DB_CONFIG["url"], DB_CONFIG["key"])
            response = supabase.table("tickets").select(
                "id", count="exact"
            ).not_.is_("ai_predicted_category", "null").execute()
            return response.count if response.count else 0
            
        else:
            engine = create_engine(DB_CONFIG["url"])
            query = "SELECT COUNT(*) FROM tickets WHERE ai_predicted_category IS NOT NULL"
            with engine.connect() as conn:
                result = conn.execute(text(query))
                return result.scalar()
    except:
        return 0


# ============================================================================
# STREAMLIT UI
# ============================================================================

def main():
    """Main Streamlit application"""
    
    # Page config
    st.set_page_config(
        page_title="Customer Support AI - LangChain",
        page_icon="🤖",
        layout="wide"
    )
    
    # Header
    st.title("🤖 Customer Support AI - LangChain Tools")
    st.markdown("*Automated ticket classification, response generation, and refund processing*")
    
    st.divider()
    
    # Input Section
    st.subheader("📝 Submit Support Ticket")
    
    col1, col2 = st.columns([1, 2])
    
    with col1:
        subject = st.text_input(
            "Subject:",
            placeholder="Brief description of the issue"
        )
    
    with col2:
        body = st.text_area(
            "Description:",
            placeholder="Provide details about your issue. Include order ID if requesting refund (e.g., ORD123)",
            height=100
        )
    
    # Process button
    if st.button("🚀 Classify & Process Ticket", type="primary", use_container_width=True):
        if not subject or not body:
            st.warning("⚠️ Please provide both subject and description.")
        else:
            # Combine for processing
            full_ticket = f"Subject: {subject}\n\n{body}"
            
            with st.spinner("Processing ticket..."):
                
                # Step 1: Triage
                category = triage_ticket.invoke({"ticket_text": full_ticket})
                
                # Step 2: Generate Response
                draft_response = generate_response.invoke({
                    "ticket_text": full_ticket,
                    "category": category
                })
                
                # Step 3: Process Refund (if applicable)
                refund_status = None
                if category == "refund":
                    refund_status = process_refund_request.invoke({"ticket_text": full_ticket})
                
                # Step 4: Save to Database
                db_saved = save_to_database(subject, body, category, draft_response)
            
            # Display Results
            st.success("✅ Ticket Processed Successfully!")
            
            st.divider()
            
            # Category
            st.subheader("📊 Classification Result")
            st.info(f"**Category:** {category.title()}")
            
            # Draft Response
            st.subheader("📧 Draft Response")
            st.text_area(
                "Generated response:",
                value=draft_response,
                height=150,
                disabled=True,
                label_visibility="collapsed"
            )
            
            # Refund Status (if applicable)
            if refund_status:
                st.subheader("💰 Refund Processing")
                if "✅" in refund_status:
                    st.success(refund_status)
                else:
                    st.warning(refund_status)
            
            # Database Status
            if db_saved:
                st.success("✅ Results saved to database")
            elif DB_CONFIG["url"]:
                st.warning("⚠️ Database connection failed - results not saved")
            else:
                st.info("ℹ️ No database configured - results not saved")
    
    st.divider()
    
    # System Metrics
    st.subheader("⚙️ System Status")
    
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        st.metric("Tools Status", "Active ✅")
    with col2:
        st.metric("LLM Model", "GPT-3.5")
    with col3:
        st.metric("Database", "Connected ✅" if DB_CONFIG["url"] else "Not Configured")
    with col4:
        total_count = get_total_classifications()
        st.metric("Total Tickets", total_count)
    
    st.divider()
    
    # Recent Classifications
    if DB_CONFIG["url"]:
        st.subheader("📊 Recent Classifications")
        
        recent_data = get_recent_classifications()
        
        if recent_data is not None and not recent_data.empty:
            # Format data
            display_data = recent_data.copy()
            display_data['ai_classified_at'] = pd.to_datetime(
                display_data['ai_classified_at']
            ).dt.strftime('%Y-%m-%d %H:%M:%S')
            
            # Rename columns
            display_data.columns = ['Subject', 'Category', 'Classified At']
            
            # Display table
            st.dataframe(
                display_data,
                use_container_width=True,
                hide_index=True
            )
            
            # Summary Stats
            if len(recent_data) > 0:
                st.markdown("---")
                col1, col2, col3 = st.columns(3)
                
                with col1:
                    total = get_total_classifications()
                    st.metric("Total Classifications", total)
                
                with col2:
                    most_common = recent_data['ai_predicted_category'].mode()
                    most_common_cat = most_common.iloc[0].title() if len(most_common) > 0 else "N/A"
                    st.metric("Most Common Category", most_common_cat)
                
                with col3:
                    st.metric("Database Status", "✅ Connected")
        else:
            st.info("💡 No classifications yet. Submit a ticket above to get started!")
    
    # Footer
    st.divider()
    st.markdown("""
    <div style='text-align: center; color: gray; padding: 20px;'>
        <small>Future Proof India</small>
    </div>
    """, unsafe_allow_html=True)


if __name__ == "__main__":
    main()

