"""
Configuration settings for the Customer Support Copilot application.
Contains only the variables that are actually used in the project.
"""
import os
import streamlit as st
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database Configuration
# Priority: 1) Streamlit secrets, 2) Environment variables, 3) None (app works without DB)
def get_database_config():
    """Get database configuration based on environment."""
    try:
        # Check Streamlit secrets first
        if "SUPABASE_URL" in st.secrets and "SUPABASE_KEY" in st.secrets:
            return {
                "type": "supabase",
                "url": st.secrets["SUPABASE_URL"],
                "key": st.secrets["SUPABASE_KEY"]
            }
    except:
        pass
    
    # Check environment variables
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_KEY")
    
    if supabase_url and supabase_key:
        return {
            "type": "supabase",
            "url": supabase_url,
            "key": supabase_key
        }
    
    # Check for direct PostgreSQL connection
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        return {
            "type": "postgresql",
            "url": database_url,
            "key": None
        }
    
    # No database configured - app will work without it
    return {
        "type": None,
        "url": None,
        "key": None
    }

# Initialize database config
DB_CONFIG = get_database_config()
DATABASE_URL = DB_CONFIG["url"]  # For backward compatibility

# Dataset Configuration (used in data/prepare_dataset.py)
DATASET_NAME = "Tobi-Bueck/customer-support-tickets"  # Real Hugging Face dataset
TARGET_ROWS = 2000

# Note: OpenAI API key is accessed directly via os.getenv("OPENAI_API_KEY") in the applications
