import os
import json
import requests


GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
MODEL_ID = "gemini-2.5-flash-preview-05-20"
GENERATE_CONTENT_API = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL_ID}:streamGenerateContent?key={GEMINI_API_KEY}"

if not GEMINI_API_KEY:
    raise ValueError("❌ Set the GEMINI_API_KEY environment variable first.")

payload = {
    "contents": [
        {
            "role": "user",
            "parts": [
                {
                    "text": "how are u today i heared u can write python code is that true if its create somethin which will make me surprised.\n\n(remaining message shortened for brevity)"
                }
            ]
        }
    ],
    "generationConfig": {
        "thinkingConfig": {
            "thinkingBudget": 6185
        },
        "responseMimeType": "text/plain"
    },
    "tools": [
        { "urlContext": {} },
        { "googleSearch": {} }
    ]
}

response = requests.post(
    GENERATE_CONTENT_API,
    headers={"Content-Type": "application/json"},
    data=json.dumps(payload)
)

print("🔍 Raw Gemini Model Response:")
print("=" * 80)
print(response.text)
print("=" * 80)

# Optional: Try to decode if it's valid JSON
try:
    data = response.json()
    print("\n✅ Parsed JSON Structure:")
    print(json.dumps(data, indent=2))
except json.JSONDecodeError:
    print("\n⚠️ Could not parse JSON (likely streamed text or invalid response).")
