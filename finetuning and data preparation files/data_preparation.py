import pandas as pd
import os

PARENT_PATH = r"C:\Users\jesha\OneDrive\Desktop\curriculam_data"

# Only Class1 for now
classes = ['Class1','Class2','Class3','Class4','Class5','Class6','Class7','Class8','Class9','Class10']
subjects = ['nepali', 'english', 'social', 'maths','science']

all_records = []

for clas in classes:
    class_path = os.path.join(PARENT_PATH, clas)
    for subject in subjects:
        subject_file = os.path.join(class_path, subject + ".json")
        print("Loading:", subject_file)
        
        try:
            # load your JSON array
            data = pd.read_json(subject_file)
            
            # extract each dialog into query/response plus metadata
            for _, row in data.iterrows():
                msgs = row["messages"]
                user_msg      = next(m["content"] for m in msgs if m["role"] == "user")
                assistant_msg = next(m["content"] for m in msgs if m["role"] == "assistant")
                
                all_records.append({
                    "class":    clas,
                    "subject":  subject,
                    "query":    user_msg,
                    "response": assistant_msg
                })
        except FileNotFoundError:
            print(f"⚠️ Warning: File not found for {clas}/{subject}.json. Skipping...")
        except Exception as e:
            print(f"❌ Error processing {clas}/{subject}.json: {e}. Skipping...")

# convert to DataFrame
df = pd.DataFrame(all_records)

# show a preview
print(df[['class','subject','query','response']].head())

# optionally save to Excel or CSV
#df.to_excel("class1_all_subjects.xlsx", index=False)
df.to_csv(r"C:\Users\jesha\OneDrive\Desktop\curriculam_data\final_data\data.csv", index=False)

print("✅ Done — saved to class1_all_subjects.csv")