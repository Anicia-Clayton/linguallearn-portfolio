import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
import pickle
from datetime import datetime, timedelta

# Predicts optimal review times based on historical performance
class ForgettingCurveModel:
    def __init__(self):
        self.model = None
        self.default_decay_rate = 0.3  # Based on Ebbinghaus research

    # Train model on historical review data
    def train(self, learning_sessions_data):
        """
        Train on historical review data
        Features: days_since_last_review, review_count, difficulty_score
        Target: successful_recall
        """
        # Prepare features
        X = learning_sessions_data[['days_since_last_review', 'review_count', 'difficulty_score']]
        y = learning_sessions_data['successful_recall']

        self.model = LinearRegression()
        self.model.fit(X, y)

        return self.model.score(X, y)

    # Predict probability of successful recall for a vocabulary card

    #def predict_recall_probability(self, days_since_review, review_count, difficulty_score):
    #    """Predict probability of successful recall"""
    #    if self.model is None:
    #        # Use exponential decay formula if no model trained
    #        return np.exp(-self.default_decay_rate * days_since_review)

    #    features = np.array([[days_since_review, review_count, difficulty_score]])
    #    prediction = self.model.predict(features)[0]

        # Clip prediction to valid probability range [0, 1]
    #    return max(0.0, min(1.0, prediction))

    # Switch to DataFames to address scikit-learn warnings, if speed becomes an issue switch back to numpy
    def predict_recall_probability(self, days_since_review, review_count, difficulty_score):
        """Predict probability of successful recall"""
        if self.model is None:
           # Use exponential decay formula if no model trained
            return np.exp(-self.default_decay_rate * days_since_review)

        # Use DataFrame with proper column names (matches training data)
        features = pd.DataFrame({
            'days_since_last_review': [days_since_review],
            'review_count': [review_count],
            'difficulty_score': [difficulty_score]
        })

        prediction = self.model.predict(features)[0]

        # Clip prediction to valid probability range [0, 1]
        return max(0.0, min(1.0, prediction))

    # Calculate optimal time for next review
    def get_optimal_review_time(self, current_recall_prob, target_recall_prob=0.8):
        """Calculate optimal time for next review"""
        # Simple heuristic: review when probability drops to 80%
        if current_recall_prob > target_recall_prob:
            return 1  # Review tomorrow
        else:
            return 0  # Review today!

    # Save model to pickle file for deployment

    #def save(self, filepath):
    #    """Save model to pickle file"""
    #    with open(filepath, 'wb') as f:
    #        pickle.dump(self, f)

    # Load model from pickle file

    #@staticmethod
    #def load(filepath):
    #    """Load model from pickle file"""
    #    with open(filepath, 'rb') as f:
    #        return pickle.load(f)

    # Save just the trained sklearn model instead of the entire instance class to address: "pickle can't find api module"
    def save(self, filepath):
        """Save model to pickle file"""
        with open(filepath, 'wb') as f:
            # Save only the sklearn model and decay rate, not the entire class
            pickle.dump({
                'sklearn_model': self.model,
                'decay_rate': self.default_decay_rate
            }, f)

    # Load model from pickle file
    @staticmethod
    def load(filepath):
        """Load model from pickle file"""
        with open(filepath, 'rb') as f:
            data = pickle.load(f)

            # Reconstruct the ForgettingCurveModel
            instance = ForgettingCurveModel()
            instance.model = data['sklearn_model']
            instance.default_decay_rate = data['decay_rate']

        return instance
