-- ============================================================================
-- Customer Support Agent - Database Setup Script
-- ============================================================================
-- This script creates the database and tables needed for the Customer Support
-- AI application using LangChain tools.
--
-- Compatible with:
-- - PostgreSQL (local or remote)
-- - Supabase (PostgreSQL-based)
--
-- Usage:
--   Local PostgreSQL:
--     psql -h localhost -U postgres -d your_database -f database_setup.sql
--     OR
--     psql -U postgres -d your_database < database_setup.sql
--
--   Supabase:
--     1. Go to Supabase Dashboard → SQL Editor
--     2. Create a new query
--     3. Copy and paste this entire script
--     4. Click "Run" or press Ctrl+Enter
-- ============================================================================

-- ============================================================================
-- Step 1: Create tickets table
-- ============================================================================

CREATE TABLE IF NOT EXISTS tickets (
    -- Primary key
    id SERIAL PRIMARY KEY,
    
    -- Ticket information
    subject TEXT NOT NULL,
    body TEXT NOT NULL,
    
    -- AI classification results
    ai_predicted_category VARCHAR(50),
    ai_confidence NUMERIC(5, 2) DEFAULT 0.95,
    ai_method VARCHAR(100) DEFAULT 'LangChain Tools',
    ai_classified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Generated response
    draft_response TEXT,
    
    -- Status and metadata
    status VARCHAR(50) DEFAULT 'processed',
    user_id VARCHAR(100) DEFAULT 'demo_user',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- Step 2: Create indexes for better query performance
-- ============================================================================

-- Index on category for filtering
CREATE INDEX IF NOT EXISTS idx_tickets_category 
    ON tickets(ai_predicted_category);

-- Index on classification timestamp for sorting (most recent first)
CREATE INDEX IF NOT EXISTS idx_tickets_classified_at 
    ON tickets(ai_classified_at DESC);

-- Index on status for filtering
CREATE INDEX IF NOT EXISTS idx_tickets_status 
    ON tickets(status);

-- Index on user_id for user-specific queries
CREATE INDEX IF NOT EXISTS idx_tickets_user_id 
    ON tickets(user_id);

-- ============================================================================
-- Step 3: Create function to auto-update updated_at timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ============================================================================
-- Step 4: Create trigger to auto-update updated_at on row updates
-- ============================================================================

DROP TRIGGER IF EXISTS update_tickets_updated_at ON tickets;
CREATE TRIGGER update_tickets_updated_at
    BEFORE UPDATE ON tickets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Step 5: Add draft_response column if it doesn't exist (for existing databases)
-- ============================================================================

-- This is safe to run multiple times - won't error if column exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tickets' AND column_name = 'draft_response'
    ) THEN
        ALTER TABLE tickets ADD COLUMN draft_response TEXT;
    END IF;
END $$;

-- ============================================================================
-- Step 6: Insert test data (OPTIONAL - uncomment to insert sample tickets)
-- ============================================================================

-- Uncomment the section below to insert sample test data:

/*
INSERT INTO tickets (
    subject, 
    body, 
    ai_predicted_category, 
    ai_confidence,
    draft_response, 
    status,
    user_id
) VALUES
(
    'Product damaged on arrival',
    'Order ORD123 arrived with the laptop screen completely broken. The package was damaged during shipping. I need a refund immediately.',
    'refund',
    0.95,
    'Thank you for contacting us regarding your damaged order. We sincerely apologize for the inconvenience. We will process a full refund for order ORD123 (Laptop - $99.99) within 3-5 business days. A confirmation email will be sent once the refund is processed.',
    'processed',
    'demo_user'
),
(
    'Cannot login to my account',
    'I forgot my password and the reset link is not working. I tried clicking the link multiple times but it says the link has expired. Please help me regain access to my account.',
    'technical',
    0.92,
    'We apologize for the login issues you are experiencing. Our technical team is investigating the password reset functionality. In the meantime, please try requesting a new password reset link. If the issue persists, we will escalate this to our support team for immediate assistance.',
    'processed',
    'demo_user'
),
(
    'Charged twice for subscription',
    'I was charged twice this month for my premium subscription. I see two charges of $29.99 on my credit card statement. This is clearly a billing error and I need one of these charges refunded.',
    'billing',
    0.98,
    'Thank you for bringing this billing issue to our attention. We have reviewed your account and confirmed the duplicate charge. We will process a refund of $29.99 within 3-5 business days. You will receive a confirmation email once the refund is completed.',
    'processed',
    'demo_user'
),
(
    'Question about product features',
    'I am considering upgrading to the premium plan. Can you tell me what additional features are included? Also, is there a trial period available?',
    'general',
    0.88,
    'Thank you for your interest in our premium plan! The premium plan includes advanced analytics, priority support, unlimited API calls, and custom integrations. Yes, we offer a 14-day free trial with no credit card required. Would you like me to set up the trial for you?',
    'processed',
    'demo_user'
),
(
    'Refund request for wrong item',
    'I ordered a wireless mouse but received a wired keyboard instead. Order number is ORD456. I want to return this and get a refund for the mouse I actually ordered.',
    'refund',
    0.96,
    'We sincerely apologize for the shipping error. We will process a full refund for order ORD456 (Mouse - $49.99) and arrange for return shipping of the incorrect item. You will receive a prepaid return label via email. The refund will be processed within 3-5 business days after we receive the returned item.',
    'processed',
    'demo_user'
),
(
    'Application crashes on startup',
    'Every time I try to open the application, it crashes immediately after the splash screen. I am using Windows 11 and have tried reinstalling but the issue persists. Error code: ERR_001',
    'technical',
    0.94,
    'We apologize for the application crashes you are experiencing. This appears to be a compatibility issue with Windows 11. Our development team is aware of this issue and working on a fix. In the meantime, please try running the application in compatibility mode for Windows 10. We will notify you once a patch is available.',
    'processed',
    'demo_user'
),
(
    'Invoice not received',
    'I paid for my subscription last month but never received an invoice or receipt. I need this for my accounting records. Can you please send me a copy?',
    'billing',
    0.91,
    'Thank you for contacting us about your invoice. We have located your payment record and will email you a copy of the invoice and receipt within 24 hours. If you need it sooner, please reply to this message and we will prioritize your request.',
    'processed',
    'demo_user'
),
(
    'Feature request',
    'I would love to see a dark mode option in the application. Many users have requested this feature. Is this something you are planning to add in the future?',
    'general',
    0.85,
    'Thank you for your feature request! We appreciate your feedback. Dark mode is indeed on our roadmap and we are planning to release it in our next major update (Q2 2024). We will notify all users once this feature is available. Thank you for being a valued customer!',
    'processed',
    'demo_user'
);
*/

-- ============================================================================
-- Step 7: Verify table structure and data
-- ============================================================================

-- View table structure
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'tickets'
ORDER BY ordinal_position;

-- View total ticket count
SELECT COUNT(*) as total_tickets FROM tickets;

-- View tickets by category (if test data was inserted)
SELECT 
    ai_predicted_category as category,
    COUNT(*) as count
FROM tickets
WHERE ai_predicted_category IS NOT NULL
GROUP BY ai_predicted_category
ORDER BY count DESC;

-- View recent tickets (if test data was inserted)
SELECT 
    id,
    subject,
    ai_predicted_category,
    status,
    ai_classified_at
FROM tickets
ORDER BY ai_classified_at DESC
LIMIT 5;

-- ============================================================================
-- Success message
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Database setup completed successfully!';
    RAISE NOTICE '📊 Table "tickets" created with all required columns.';
    RAISE NOTICE '🔍 Indexes created for optimal query performance.';
    RAISE NOTICE '⚡ Trigger created for auto-updating timestamps.';
    RAISE NOTICE '';
    RAISE NOTICE '💡 To insert test data, uncomment the INSERT statements above.';
    RAISE NOTICE '📝 You can now run the application: streamlit run app_langchain.py';
END $$;
