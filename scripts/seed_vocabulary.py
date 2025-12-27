#!/usr/bin/env python3
"""
Vocabulary Database Seeding Script
Seeds vocabulary_cards table with Spanish, French, and Mandarin vocabulary

Usage:
    python3 scripts/seed_vocabulary.py [user_id]

Example:
    python3 scripts/seed_vocabulary.py 1
"""

import json
import sys
import os
from pathlib import Path

# Add parent directory to path to import api modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from api.utils.db_connection import db

# Language configuration
LANGUAGES = {
    'spanish': {
        'file': 'data/seed_vocabulary/spanish_vocabulary_seed.json',
        'language_code': 'es-do'
    },
    'french': {
        'file': 'data/seed_vocabulary/french_vocabulary_seed.json',
        'language_code': 'fr'
    },
    'mandarin': {
        'file': 'data/seed_vocabulary/mandarin_vocabulary_seed.json',
        'language_code': 'zh-tw'
    }
}

def seed_vocabulary(user_id=1):
    """
    Seed vocabulary for a given user

    Args:
        user_id: User to assign vocabulary cards to (default: demo user)
    """
    print(f"\n🌱 Seeding vocabulary for user_id={user_id}")

    # Get database connection using shared connection module
    conn = db.get_connection()
    cursor = conn.cursor()

    total_inserted = 0

    try:
        for lang_name, lang_config in LANGUAGES.items():
            print(f"\n📚 Processing {lang_name.title()}...")

            # Load vocabulary from JSON
            file_path = lang_config['file']
            if not os.path.exists(file_path):
                print(f"   ⚠️  Warning: File not found: {file_path}")
                continue

            with open(file_path, 'r', encoding='utf-8') as f:
                vocabulary = json.load(f)

            # Insert each word
            for word in vocabulary:
                cursor.execute("""
                    INSERT INTO vocabulary_cards (
                        user_id, language_code,
                        word_native, word_target, context_sentence,
                        difficulty_level, category, source
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    user_id,
                    lang_config['language_code'],
                    word['word_native'],
                    word['word_target'],
                    word['context_sentence'],
                    word['difficulty_level'],
                    word['category'],
                    word['source']
                ))

            conn.commit()
            count = len(vocabulary)
            total_inserted += count
            print(f"   ✅ Inserted {count} {lang_name} words")

        print(f"\n🎉 Success! Total vocabulary inserted: {total_inserted} words")
        print(f"   Languages: Spanish (Dominican), French, Mandarin (Taiwan)")

    except Exception as e:
        conn.rollback()
        print(f"\n❌ Error seeding vocabulary: {e}")
        raise

    finally:
        cursor.close()
        db.return_connection(conn)

def verify_seeding(user_id=1):
    """
    Verify vocabulary was seeded correctly

    Args:
        user_id: User ID to check
    """
    print(f"\n🔍 Verifying vocabulary for user_id={user_id}...")

    conn = db.get_connection()
    cursor = conn.cursor()

    try:
        # Get total count
        cursor.execute("""
            SELECT COUNT(*)
            FROM vocabulary_cards
            WHERE user_id = %s
        """, (user_id,))
        total_count = cursor.fetchone()[0]
        print(f"   Total vocabulary cards: {total_count}")

        # Get count by language
        cursor.execute("""
            SELECT language_code, COUNT(*) as count
            FROM vocabulary_cards
            WHERE user_id = %s
            GROUP BY language_code
            ORDER BY language_code
        """, (user_id,))

        results = cursor.fetchall()
        print(f"\n   Breakdown by language:")
        for row in results:
            lang_code, count = row
            print(f"   - {lang_code}: {count} words")

        # Get count by source
        cursor.execute("""
            SELECT language_code, source, COUNT(*) as count
            FROM vocabulary_cards
            WHERE user_id = %s
            GROUP BY language_code, source
            ORDER BY language_code, source
        """, (user_id,))

        results = cursor.fetchall()
        print(f"\n   Breakdown by source:")
        for row in results:
            lang_code, source, count = row
            print(f"   - {lang_code} ({source}): {count} words")

        # Sample vocabulary from each language
        print(f"\n   Sample vocabulary:")
        cursor.execute("""
            SELECT language_code, word_native, word_target, category
            FROM vocabulary_cards
            WHERE user_id = %s
            ORDER BY language_code, card_id
            LIMIT 9
        """, (user_id,))

        samples = cursor.fetchall()
        current_lang = None
        for row in samples[:3]:  # Show 1 from each language
            lang_code, word_native, word_target, category = row
            if lang_code != current_lang:
                print(f"   {lang_code}: {word_native} → {word_target} ({category})")
                current_lang = lang_code

        # Verify Mandarin pinyin format
        cursor.execute("""
            SELECT word_target, context_sentence
            FROM vocabulary_cards
            WHERE user_id = %s
            AND language_code = 'zh-tw'
            LIMIT 3
        """, (user_id,))

        mandarin_samples = cursor.fetchall()
        if mandarin_samples:
            print(f"\n   Mandarin pinyin verification:")
            for word_target, context_sentence in mandarin_samples:
                # Check if pinyin is embedded (contains parentheses)
                has_pinyin = '(' in context_sentence and ')' in context_sentence
                status = "✅" if has_pinyin else "⚠️"
                print(f"   {status} {word_target}: {context_sentence[:60]}...")

        print(f"\n✅ Verification complete!")

    except Exception as e:
        print(f"\n❌ Error verifying vocabulary: {e}")

    finally:
        cursor.close()
        db.return_connection(conn)

if __name__ == "__main__":
    # Get user_id from command line or use demo user
    user_id = int(sys.argv[1]) if len(sys.argv) > 1 else 1

    print("="*60)
    print("LinguaLearn AI - Vocabulary Seeding Script")
    print("="*60)

    # Seed vocabulary
    seed_vocabulary(user_id)

    # Verify seeding
    verify_seeding(user_id)

    print("\n" + "="*60)
    print("✨ Vocabulary seeding complete!")
    print("="*60)
    print("\n📊 Summary:")
    print("   - Spanish (es-do): 100 words (70 standard + 30 Dominican slang)")
    print("   - French (fr): 101 words (standard French)")
    print("   - Mandarin (zh-tw): 99 words (HSK 1, Traditional Chinese)")
    print("   - Total: 300 vocabulary cards")
    print("\n📝 Next steps:")
    print("   1. Test API endpoints: GET /api/vocabulary/user/1")
    print("   2. Test language filters: ?language=es-do, ?language=fr, ?language=zh-tw")
    print("   3. Test predictions: POST /api/predictions/card/{card_id}")
    print("="*60 + "\n")
