-- LinguaLearn AI - Complete Database Schema
-- PostgreSQL 14+
-- 12+ Tables for Multi-Modal Language Learning Platform

-- ============================================
-- CORE USER MANAGEMENT
-- ============================================

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('learner', 'tutor', 'admin')),
    account_status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (account_status IN ('active', 'inactive', 'at_risk', 'suspended')),
    created_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP,
    email_verified BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(account_status);

CREATE TABLE user_profiles (
    profile_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    timezone VARCHAR(50) DEFAULT 'UTC',
    learning_style VARCHAR(50) CHECK (learning_style IN ('visual', 'auditory', 'kinesthetic', 'reading_writing')),
    preferred_study_time VARCHAR(20) CHECK (preferred_study_time IN ('morning', 'afternoon', 'evening', 'night')),
    native_language VARCHAR(50) DEFAULT 'english',
    bio TEXT,
    profile_image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE INDEX idx_profiles_user ON user_profiles(user_id);

-- ============================================
-- LANGUAGE & VOCABULARY MANAGEMENT
-- ============================================

CREATE TABLE languages (
    language_code VARCHAR(10) PRIMARY KEY,
    language_name VARCHAR(100) NOT NULL,
    native_name VARCHAR(100),
    dialect VARCHAR(100),
    region VARCHAR(100),
    tier VARCHAR(20) NOT NULL DEFAULT 'basic' CHECK (tier IN ('full', 'basic', 'planned')),
    is_signed BOOLEAN DEFAULT FALSE,
    writing_system VARCHAR(50),
    resource_links JSONB,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert initial languages
INSERT INTO languages (language_code, language_name, native_name, dialect, region, tier, is_signed, writing_system) VALUES
('es', 'Spanish', 'Español', 'Standard', 'Global', 'full', FALSE, 'latin'),
('es-do', 'Spanish', 'Español', 'Dominican', 'Caribbean', 'full', FALSE, 'latin'),
('pt', 'Portuguese', 'Português', 'Brazilian', 'South America', 'full', FALSE, 'latin'),
('sw', 'Swahili', 'Kiswahili', 'Standard', 'East Africa', 'basic', FALSE, 'latin'),
('ro', 'Romanian', 'Română', 'Standard', 'Eastern Europe', 'basic', FALSE, 'latin'),
('zh', 'Mandarin', '普通话', 'Mainland', 'East Asia', 'full', FALSE, 'simplified_chinese'),
('zh-tw', 'Mandarin', '國語', 'Taiwan', 'East Asia', 'full', FALSE, 'traditional_chinese'),
('ha', 'Hausa', 'Harshen Hausa', 'Standard', 'West Africa', 'basic', FALSE, 'latin'),
('tw', 'Akan Twi', 'Twi', 'Asante', 'West Africa', 'basic', FALSE, 'latin'),
('tl', 'Tagalog', 'Tagalog', 'Manila', 'Southeast Asia', 'basic', FALSE, 'latin'),
('ar-eg', 'Egyptian Arabic', 'العربية المصرية', 'Egyptian', 'North Africa', 'basic', FALSE, 'arabic'),
('fr', 'French', 'Français', 'Standard', 'Global', 'full', FALSE, 'latin'),
('asl', 'American Sign Language', 'ASL', 'American', 'North America', 'full', TRUE, 'none'),
('ht', 'Haitian Creole', 'Kreyòl Ayisyen', 'Standard', 'Caribbean', 'full', FALSE, 'latin');

CREATE TABLE user_languages (
    user_language_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    language_code VARCHAR(10) REFERENCES languages(language_code),
    proficiency_level VARCHAR(20) CHECK (proficiency_level IN ('beginner', 'intermediate', 'advanced', 'fluent')),
    started_learning_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, language_code)
);

CREATE INDEX idx_user_languages_user ON user_languages(user_id);
CREATE INDEX idx_user_languages_lang ON user_languages(language_code);

CREATE TABLE vocabulary_cards (
    card_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    language_code VARCHAR(10) REFERENCES languages(language_code),
    word_native VARCHAR(200) NOT NULL,
    word_target VARCHAR(200) NOT NULL,
    context_sentence TEXT,
    difficulty_level INTEGER CHECK (difficulty_level BETWEEN 1 AND 5),
    category VARCHAR(50),
    times_reviewed INTEGER DEFAULT 0,
    times_correct INTEGER DEFAULT 0,
    times_incorrect INTEGER DEFAULT 0,
    last_reviewed_at TIMESTAMP,
    next_review_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    source VARCHAR(50) DEFAULT 'manual' CHECK (source IN ('manual', 'ankideck', 'practice_activity'))
);

CREATE INDEX idx_vocab_user ON vocabulary_cards(user_id);
CREATE INDEX idx_vocab_lang ON vocabulary_cards(language_code);
CREATE INDEX idx_vocab_next_review ON vocabulary_cards(next_review_at);
CREATE INDEX idx_vocab_source ON vocabulary_cards(source);

CREATE TABLE vocabulary_dialectal_variants (
    variant_id SERIAL PRIMARY KEY,
    card_id INTEGER REFERENCES vocabulary_cards(card_id) ON DELETE CASCADE,
    dialect VARCHAR(100) NOT NULL,
    variant_text VARCHAR(200) NOT NULL,
    usage_notes TEXT,
    audio_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_variants_card ON vocabulary_dialectal_variants(card_id);

CREATE TABLE asl_vocabulary (
    asl_card_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    sign_name VARCHAR(100) NOT NULL,
    video_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    difficulty_level INTEGER CHECK (difficulty_level BETWEEN 1 AND 5),
    category VARCHAR(50),
    description TEXT,
    times_practiced INTEGER DEFAULT 0,
    last_practiced_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_asl_user ON asl_vocabulary(user_id);
CREATE INDEX idx_asl_category ON asl_vocabulary(category);

-- ============================================
-- PRACTICE & LEARNING SESSIONS
-- ============================================

CREATE TABLE learning_sessions (
    session_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    language_code VARCHAR(10) REFERENCES languages(language_code),
    session_date TIMESTAMP NOT NULL,
    duration_minutes INTEGER,
    cards_reviewed INTEGER,
    accuracy_rate DECIMAL(5,2) CHECK (accuracy_rate BETWEEN 0 AND 1),
    session_type VARCHAR(50) CHECK (session_type IN ('flashcard', 'quiz', 'conversation', 'writing', 'reading')),
    completed BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_sessions_user ON learning_sessions(user_id);
CREATE INDEX idx_sessions_date ON learning_sessions(session_date);
CREATE INDEX idx_sessions_type ON learning_sessions(session_type);

CREATE TABLE practice_activities (
    activity_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    language_code VARCHAR(10) REFERENCES languages(language_code),
    activity_type VARCHAR(50) NOT NULL CHECK (activity_type IN ('journal', 'music', 'show', 'book', 'conversation', 'movie', 'podcast', 'other')),
    skill_focus VARCHAR(50) CHECK (skill_focus IN ('listening', 'speaking', 'reading', 'writing', 'input', 'mixed')),
    title VARCHAR(200),
    content TEXT,
    duration_minutes INTEGER,
    notes TEXT,
    new_vocabulary_discovered TEXT[],
    created_at TIMESTAMP DEFAULT NOW(),
    reviewed_by_tutor BOOLEAN DEFAULT FALSE,
    tutor_feedback TEXT,
    tutor_reviewed_at TIMESTAMP
);

CREATE INDEX idx_activities_user ON practice_activities(user_id);
CREATE INDEX idx_activities_type ON practice_activities(activity_type);
CREATE INDEX idx_activities_date ON practice_activities(created_at);
CREATE INDEX idx_activities_tutor_review ON practice_activities(reviewed_by_tutor);

CREATE TABLE language_assignments (
    assignment_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    language_code VARCHAR(10) REFERENCES languages(language_code),
    assignment_type VARCHAR(50) NOT NULL CHECK (assignment_type IN ('person', 'task', 'location', 'time_of_day')),
    assignment_name VARCHAR(200) NOT NULL,
    description TEXT,
    frequency VARCHAR(50) CHECK (frequency IN ('daily', 'weekly', 'as_needed')),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_assignments_user ON language_assignments(user_id);
CREATE INDEX idx_assignments_active ON language_assignments(active);

CREATE TABLE practice_checkboxes (
    checkbox_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    assignment_id INTEGER REFERENCES language_assignments(assignment_id) ON DELETE CASCADE,
    practice_date DATE NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(assignment_id, practice_date)
);

CREATE INDEX idx_checkboxes_user ON practice_checkboxes(user_id);
CREATE INDEX idx_checkboxes_date ON practice_checkboxes(practice_date);

-- ============================================
-- TUTOR-LEARNER RELATIONSHIPS
-- ============================================

CREATE TABLE tutor_assignments (
    tutor_assignment_id SERIAL PRIMARY KEY,
    tutor_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    learner_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    language_code VARCHAR(10) REFERENCES languages(language_code),
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused', 'cancelled')),
    meeting_frequency VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    CHECK (tutor_id != learner_id)
);

CREATE INDEX idx_tutor_assignments_tutor ON tutor_assignments(tutor_id);
CREATE INDEX idx_tutor_assignments_learner ON tutor_assignments(learner_id);
CREATE INDEX idx_tutor_assignments_status ON tutor_assignments(status);

CREATE TABLE tutor_recommendations (
    recommendation_id SERIAL PRIMARY KEY,
    tutor_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    learner_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    recommendation_type VARCHAR(50) CHECK (recommendation_type IN ('listening', 'speaking', 'reading', 'writing', 'vocabulary', 'grammar', 'general')),
    activity_suggestion TEXT NOT NULL,
    reasoning TEXT,
    priority VARCHAR(20) CHECK (priority IN ('low', 'medium', 'high')),
    created_at TIMESTAMP DEFAULT NOW(),
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_at TIMESTAMP
);

CREATE INDEX idx_recommendations_learner ON tutor_recommendations(learner_id);
CREATE INDEX idx_recommendations_acknowledged ON tutor_recommendations(acknowledged);

-- ============================================
-- ML PREDICTIONS & ANALYTICS
-- ============================================

CREATE TABLE ml_predictions (
    prediction_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    card_id INTEGER REFERENCES vocabulary_cards(card_id) ON DELETE SET NULL,
    prediction_type VARCHAR(50) NOT NULL CHECK (prediction_type IN ('forgetting_curve', 'churn_risk', 'optimal_study_time', 'learning_pattern')),
    predicted_at TIMESTAMP DEFAULT NOW(),
    confidence_score DECIMAL(5,2) CHECK (confidence_score BETWEEN 0 AND 1),
    model_version VARCHAR(50) NOT NULL,
    prediction_result JSONB NOT NULL
);

CREATE INDEX idx_predictions_user ON ml_predictions(user_id);
CREATE INDEX idx_predictions_type ON ml_predictions(prediction_type);
CREATE INDEX idx_predictions_date ON ml_predictions(predicted_at);

CREATE TABLE model_metrics (
    metric_id SERIAL PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    model_version VARCHAR(50) NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    metric_value DECIMAL(10,4),
    training_date TIMESTAMP NOT NULL,
    dataset_size INTEGER,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_metrics_model ON model_metrics(model_name, model_version);

-- ============================================
-- EXTERNAL API INTEGRATION TRACKING
-- ============================================

CREATE TABLE ankideck_sync_log (
    sync_id SERIAL PRIMARY KEY,
    language_code VARCHAR(10) REFERENCES languages(language_code),
    deck_id VARCHAR(100),
    sync_started_at TIMESTAMP NOT NULL,
    sync_completed_at TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('pending', 'success', 'failed', 'partial')),
    cards_fetched INTEGER,
    cards_imported INTEGER,
    error_message TEXT
);

CREATE INDEX idx_sync_status ON ankideck_sync_log(status);
CREATE INDEX idx_sync_date ON ankideck_sync_log(sync_started_at);

-- ============================================
-- AUDIT & LOGGING
-- ============================================

CREATE TABLE user_activity_log (
    log_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    activity_type VARCHAR(100) NOT NULL,
    activity_description TEXT,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_activity_user ON user_activity_log(user_id);
CREATE INDEX idx_activity_date ON user_activity_log(created_at);
CREATE INDEX idx_activity_type ON user_activity_log(activity_type);

-- ============================================
-- VIEWS FOR COMMON QUERIES
-- ============================================

CREATE VIEW active_learners_summary AS
SELECT 
    u.user_id,
    u.username,
    u.email,
    u.account_status,
    COUNT(DISTINCT ul.language_code) as languages_learning,
    COUNT(DISTINCT vc.card_id) as total_vocabulary,
    COUNT(DISTINCT ls.session_id) as total_sessions,
    MAX(ls.session_date) as last_session_date,
    COALESCE(AVG(ls.accuracy_rate), 0) as avg_accuracy
FROM users u
LEFT JOIN user_languages ul ON u.user_id = ul.user_id AND ul.is_active = TRUE
LEFT JOIN vocabulary_cards vc ON u.user_id = vc.user_id
LEFT JOIN learning_sessions ls ON u.user_id = ls.user_id
WHERE u.role = 'learner'
GROUP BY u.user_id, u.username, u.email, u.account_status;

CREATE VIEW tutor_student_overview AS
SELECT 
    ta.tutor_assignment_id,
    t.user_id as tutor_id,
    t.username as tutor_name,
    l.user_id as learner_id,
    l.username as learner_name,
    ta.language_code,
    lang.language_name,
    ta.status,
    COUNT(DISTINCT pa.activity_id) as activities_to_review,
    COUNT(DISTINCT tr.recommendation_id) as pending_recommendations
FROM tutor_assignments ta
JOIN users t ON ta.tutor_id = t.user_id
JOIN users l ON ta.learner_id = l.user_id
JOIN languages lang ON ta.language_code = lang.language_code
LEFT JOIN practice_activities pa ON l.user_id = pa.user_id 
    AND pa.reviewed_by_tutor = FALSE
    AND pa.language_code = ta.language_code
LEFT JOIN tutor_recommendations tr ON l.user_id = tr.learner_id 
    AND tr.acknowledged = FALSE
WHERE ta.status = 'active'
GROUP BY ta.tutor_assignment_id, t.user_id, t.username, l.user_id, 
         l.username, ta.language_code, lang.language_name, ta.status;

-- ============================================
-- FUNCTIONS FOR COMMON OPERATIONS
-- ============================================

-- Function to calculate next review date based on performance
CREATE OR REPLACE FUNCTION calculate_next_review(
    p_times_correct INTEGER,
    p_times_reviewed INTEGER,
    p_last_reviewed_at TIMESTAMP
) RETURNS TIMESTAMP AS $$
DECLARE
    accuracy DECIMAL;
    days_until_next INTEGER;
BEGIN
    IF p_times_reviewed = 0 THEN
        RETURN p_last_reviewed_at + INTERVAL '1 day';
    END IF;
    
    accuracy := p_times_correct::DECIMAL / p_times_reviewed::DECIMAL;
    
    -- Simple spaced repetition: 1-14 days based on accuracy
    days_until_next := FLOOR(1 + (accuracy * 13));
    
    RETURN p_last_reviewed_at + (days_until_next || ' days')::INTERVAL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update next_review_at automatically
CREATE OR REPLACE FUNCTION update_next_review_trigger()
RETURNS TRIGGER AS $$
BEGIN
    NEW.next_review_at := calculate_next_review(
        NEW.times_correct,
        NEW.times_reviewed,
        NEW.last_reviewed_at
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER vocabulary_review_update
    BEFORE UPDATE ON vocabulary_cards
    FOR EACH ROW
    WHEN (OLD.times_reviewed IS DISTINCT FROM NEW.times_reviewed)
    EXECUTE FUNCTION update_next_review_trigger();

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Additional composite indexes for common query patterns
CREATE INDEX idx_vocab_user_lang ON vocabulary_cards(user_id, language_code);
CREATE INDEX idx_vocab_due_review ON vocabulary_cards(user_id, next_review_at) WHERE next_review_at <= NOW();
CREATE INDEX idx_activities_user_date ON practice_activities(user_id, created_at DESC);
CREATE INDEX idx_sessions_user_date ON learning_sessions(user_id, session_date DESC);
CREATE INDEX idx_predictions_user_type ON ml_predictions(user_id, prediction_type, predicted_at DESC);

-- ============================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON TABLE users IS 'Core user accounts with role-based access control';
COMMENT ON TABLE user_profiles IS 'Extended user profile information and learning preferences';
COMMENT ON TABLE languages IS 'Supported languages with dialect and regional information';
COMMENT ON TABLE vocabulary_cards IS 'User vocabulary items with spaced repetition tracking';
COMMENT ON TABLE practice_activities IS 'Multi-modal practice tracking (journal, media, conversations)';
COMMENT ON TABLE language_assignments IS 'Task/person-based language practice assignments';
COMMENT ON TABLE asl_vocabulary IS 'ASL-specific vocabulary with video demonstration links';
COMMENT ON TABLE ml_predictions IS 'Machine learning predictions for forgetting curves and churn';
COMMENT ON TABLE ankideck_sync_log IS 'Tracking log for AnkiDeck API synchronization jobs';

-- Grant appropriate permissions (adjust as needed for your setup)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO linguallearn_api;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO linguallearn_api;
