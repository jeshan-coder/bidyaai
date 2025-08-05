# -*- coding: utf-8 -*-
"""
Created on Mon Jul 28 22:22:45 2025

@author: jesha
"""
import pandas as pd
from sklearn.model_selection import train_test_split
import os
PARENT_PATH = r"C:\Users\jesha\OneDrive\Desktop\curriculam_data"
# 1. Load your full dataset

path_to_data=os.path.join(PARENT_PATH,"final_data","data.csv")
df = pd.read_csv(path_to_data)  # expects columns: class, subject, query, response, etc.

# Prepare lists to collect splits
train_parts = []
val_parts   = []
test_parts  = []

# 2. Loop over each (class, subject) group
for (clas, subj), group in df.groupby(["class", "subject"]):
    # If the group is too small to split, you may want to handle it specially.
    # Here we just apply the same ratios.
    
    # 2a. First split off test (10% of this group's rows)
    train_val, test = train_test_split(
        group, 
        test_size=0.10, 
        random_state=42, 
        shuffle=True
    )
    
    # 2b. Then split train_val into train (≈80%) and val (≈10%):
    # Since train_val is 90% of original, val_size = 0.10/0.90 ≈ 0.1111
    train, val = train_test_split(
        train_val,
        test_size=0.1111, 
        random_state=42, 
        shuffle=True
    )
    
    # 2c. Tag and collect
    train_parts.append(train)
    val_parts.append(val)
    test_parts.append(test)

# 3. Concatenate all group‐wise splits
train_df = pd.concat(train_parts).reset_index(drop=True)
val_df   = pd.concat(val_parts).reset_index(drop=True)
test_df  = pd.concat(test_parts).reset_index(drop=True)

# 4. (Optional) Shuffle final sets
train_df = train_df.sample(frac=1, random_state=42).reset_index(drop=True)
val_df   = val_df.sample(frac=1, random_state=42).reset_index(drop=True)
test_df  = test_df.sample(frac=1, random_state=42).reset_index(drop=True)

# 5. Save to files
train_df.to_csv(os.path.join(PARENT_PATH,"final_data","dataset_train.csv"), index=False)
val_df.to_csv(os.path.join(PARENT_PATH,"final_data","dataset_val.csv"), index=False)
test_df.to_csv(os.path.join(PARENT_PATH,"final_data","dataset_test.csv"), index=False)

print("Splits created:")
print(f" • Train: {len(train_df)} rows")
print(f" • Val:   {len(val_df)} rows")
print(f" • Test:  {len(test_df)} rows")

