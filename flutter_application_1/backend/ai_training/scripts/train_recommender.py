"""Train a simple furniture suitability classifier from manually reviewed examples.

Install optional dependency: python -m pip install pandas scikit-learn joblib
Data are manually labeled (1=suitable, 0=unsuitable), no fabricated training accuracy.
"""
from pathlib import Path


def main():
    root = Path(__file__).resolve().parents[1]
    path = root / 'templates' / 'recommendation_labels.csv'
    import pandas as pd
    import joblib
    from sklearn.compose import ColumnTransformer
    from sklearn.pipeline import Pipeline
    from sklearn.preprocessing import OneHotEncoder
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.model_selection import GroupShuffleSplit
    from sklearn.metrics import classification_report

    frame = pd.read_csv(path)
    if len(frame) < 100 or frame['room_id'].nunique() < 10 or frame['suitable'].nunique() < 2:
        raise SystemExit('Collect at least 100 labeled pairs from >=10 different rooms with positive and negative examples first.')
    categorical = ['room_type', 'style', 'furniture_category', 'furniture_style', 'material', 'color']
    numeric = ['room_width_cm', 'room_length_cm', 'budget_mnt', 'furniture_width_cm',
               'furniture_depth_cm', 'price_mnt']
    X = frame[categorical + numeric]
    y = frame['suitable'].astype(int)
    groups = frame['room_id']
    train_idx, test_idx = next(GroupShuffleSplit(n_splits=1, test_size=.2, random_state=42).split(X, y, groups))
    if y.iloc[train_idx].nunique() < 2:
        raise SystemExit('Training split needs both suitable=0 and suitable=1 examples.')
    preprocess = ColumnTransformer([
        ('categories', OneHotEncoder(handle_unknown='ignore'), categorical),
        ('numbers', 'passthrough', numeric),
    ])
    model = Pipeline([
        ('preprocess', preprocess),
        ('classifier', RandomForestClassifier(n_estimators=150, random_state=42,
                                              class_weight='balanced', min_samples_leaf=2)),
    ])
    model.fit(X.iloc[train_idx], y.iloc[train_idx])
    predictions = model.predict(X.iloc[test_idx])
    print(classification_report(y.iloc[test_idx], predictions, zero_division=0))
    out = root / 'runs' / 'recommendations'
    out.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, out / 'furniture_ranker.joblib')
    print('Saved model:', out / 'furniture_ranker.joblib')
    print('Important: manually assigned labels are not evidence of user preference until validated with real users.')


if __name__ == '__main__':
    main()
