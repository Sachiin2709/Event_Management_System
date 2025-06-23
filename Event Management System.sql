-- Event Management System Database
-- Created for DevifyX MySQL Core Assignment

-- Database creation
DROP DATABASE IF EXISTS event_management;
CREATE DATABASE event_management;
USE event_management;

-- User Management Tables
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT 'Stores user account information';

CREATE TABLE user_roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(30) NOT NULL UNIQUE,
    description VARCHAR(255)
) COMMENT 'Defines available user roles (organizer, attendee, admin)';

CREATE TABLE user_role_mapping (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES user_roles(role_id) ON DELETE CASCADE
) COMMENT 'Maps users to their roles (many-to-many relationship)';

-- Venue Management Tables
CREATE TABLE venues (
    venue_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    capacity INT NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT 'Stores venue information for events';

CREATE TABLE venue_sections (
    section_id INT AUTO_INCREMENT PRIMARY KEY,
    venue_id INT NOT NULL,
    section_name VARCHAR(50) NOT NULL,
    description VARCHAR(255),
    capacity INT NOT NULL,
    FOREIGN KEY (venue_id) REFERENCES venues(venue_id) ON DELETE CASCADE
) COMMENT 'Defines sections within venues for seat management';

-- Event Management Tables
CREATE TABLE event_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255)
) COMMENT 'Categories for events (e.g., Concert, Conference)';

CREATE TABLE events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    organizer_id INT NOT NULL,
    category_id INT NOT NULL,
    venue_id INT,
    title VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    start_datetime DATETIME NOT NULL,
    end_datetime DATETIME NOT NULL,
    status ENUM('draft', 'published', 'cancelled', 'completed') NOT NULL DEFAULT 'draft',
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_pattern VARCHAR(50),
    image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (organizer_id) REFERENCES users(user_id),
    FOREIGN KEY (category_id) REFERENCES event_categories(category_id),
    FOREIGN KEY (venue_id) REFERENCES venues(venue_id),
    CHECK (end_datetime > start_datetime)
) COMMENT 'Main table for event information';

CREATE TABLE event_schedule (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    session_title VARCHAR(100) NOT NULL,
    description TEXT,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    speaker_name VARCHAR(100),
    speaker_bio TEXT,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    CHECK (end_time > start_time)
) COMMENT 'Detailed schedule for multi-session events';

-- Ticketing System Tables
CREATE TABLE ticket_types (
    ticket_type_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(255),
    price DECIMAL(10, 2) NOT NULL,
    quantity_available INT NOT NULL,
    sales_start DATETIME NOT NULL,
    sales_end DATETIME NOT NULL,
    max_per_user INT DEFAULT 1,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    CHECK (sales_end > sales_start),
    CHECK (quantity_available >= 0),
    CHECK (max_per_user > 0)
) COMMENT 'Defines different ticket types for events';

CREATE TABLE tickets (
    ticket_id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_type_id INT NOT NULL,
    user_id INT NOT NULL,
    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('active', 'cancelled', 'redeemed') DEFAULT 'active',
    seat_number VARCHAR(20),
    section_id INT,
    FOREIGN KEY (ticket_type_id) REFERENCES ticket_types(ticket_type_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (section_id) REFERENCES venue_sections(section_id)
) COMMENT 'Individual tickets purchased by users';

-- RSVP System Tables
CREATE TABLE rsvps (
    rsvp_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    response ENUM('confirmed', 'waitlisted', 'cancelled') NOT NULL,
    response_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    guests INT DEFAULT 0,
    notes TEXT,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    UNIQUE KEY (event_id, user_id)
) COMMENT 'Tracks user RSVPs for events';

-- Notification System Tables
CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    event_id INT,
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    notification_type ENUM('reminder', 'update', 'promotional', 'system') NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE SET NULL
) COMMENT 'Tracks notifications sent to users';

-- Feedback and Ratings Tables
CREATE TABLE event_feedback (
    feedback_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    UNIQUE KEY (event_id, user_id)
) COMMENT 'Stores attendee feedback for events';

-- Sponsorship Tables (Bonus Feature)
CREATE TABLE sponsors (
    sponsor_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    logo_url VARCHAR(255),
    website_url VARCHAR(255),
    contact_email VARCHAR(100),
    contact_phone VARCHAR(20)
) COMMENT 'Information about event sponsors';

CREATE TABLE sponsorship_tiers (
    tier_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    min_amount DECIMAL(10, 2) NOT NULL,
    benefits TEXT
) COMMENT 'Defines different sponsorship tiers';

CREATE TABLE event_sponsors (
    event_id INT NOT NULL,
    sponsor_id INT NOT NULL,
    tier_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    agreement_details TEXT,
    PRIMARY KEY (event_id, sponsor_id),
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    FOREIGN KEY (sponsor_id) REFERENCES sponsors(sponsor_id),
    FOREIGN KEY (tier_id) REFERENCES sponsorship_tiers(tier_id)
) COMMENT 'Maps sponsors to events with tier information';

-- Indexes for performance optimization
CREATE INDEX idx_events_datetime ON events(start_datetime, end_datetime);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_tickets_user ON tickets(user_id);
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_rsvps_event_user ON rsvps(event_id, user_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);