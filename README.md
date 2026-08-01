markdown

# Maven Analytics Data Drill #15: Readmission Radar

## 📌 The Challenge

**Goal:** Calculate the hospital's 30-day readmission rate from 623 inpatient stay records.

**Dataset:** CSV file with four columns:
- `admission_id` – Unique identifier for each admission
- `patient_id` – Unique identifier for each patient
- `admission_date` – Date the patient was admitted
- `discharge_date` – Date the patient was discharged

**Definition:** The 30-day readmission rate is calculated as:

> **(30-day readmissions) / (discharges)**

**Source:** This dataset is part of Maven Analytics' Data Drill challenge series. You can access the original dataset here: [https://mavenanalytics.io/data-drills/readmission-radar?utm_source=email&utm_campaign=datadrill_readmissionradar_email_udemy]

**Key constraint:** Each `admission_id` is unique, but a single patient can have multiple admissions and discharges over time. We need to count readmissions correctly without overcounting.

---

## 🧠 My Thinking Process

Before writing any code, I asked myself:

### 1. What exactly is the business question?  
Hospitals care about readmission rates because they reflect the effectiveness of patient care and treatment. A high readmission rate may indicate that patients need repetitive care, which could point to shortcomings in patient care or discharge planning. Conversely, a low readmission rate suggests patients are recovering well and don't need to return.

The **30-day readmission rate** helps hospitals evaluate their service quality and identify areas for improvement. If the rate is high, leadership can investigate what's driving it—whether it's inadequate follow-up care, discharge decisions that were made too early, or gaps in patient education. If the rate is low, it's a signal that the hospital is doing well in supporting patients after they leave.

### 2. What does the "30-day window" mean?
This is the most important question. A readmission is only counted if:

- The patient returns to the hospital **after** their discharge
- The return happens **within 30 days** of that discharge

So for each discharge, I need to check: *"Did this same patient have any admission in the 30 days following this discharge?"*

### 3. How do I avoid overcounting?

This was the trickiest part. I initially wondered: *"What about a patient who has multiple admissions within the same 30-day window?"*

Then I realized the key insight: **for a patient to be admitted, they must first have been discharged.**

This means:
- Each discharge opens up a **new 30-day window**
- A readmission is tied to **one specific discharge**
- If a patient is admitted multiple times within a 30-day window, each readmission is associated with a different discharge date

This prevents overcounting because each discharge is evaluated independently.

---

## 💻 My SQL Solution

I used a **self-join** with a Common Table Expression (CTE) to solve this:

```sql
WITH cte AS (
    SELECT 
        pr1.patient_id, 
        pr1.discharge_date AS index_discharge,
        MIN(pr2.admission_date) AS readmission_date 
    FROM patient_records pr1
    LEFT JOIN patient_records pr2
        ON pr1.patient_id = pr2.patient_id 
        AND pr2.admission_date > pr1.discharge_date
        AND DATEDIFF(pr2.admission_date, pr1.discharge_date) <= 30
    GROUP BY pr1.patient_id, pr1.discharge_date
)
SELECT 
    ROUND(COUNT(readmission_date) / COUNT(*) * 100, 0) AS thirty_day_readmission_rate 
FROM cte;
```

---

## 🔍 How This Solution Works

### Step 1: The Self-Join

I joined `patient_records` to itself using a `LEFT JOIN`. For each discharge (`pr1`), I looked for any admission (`pr2`) that belongs to the same patient and meets two conditions:

| Condition | Why It Matters |
|--------------|---------------------|
| `pr2.admission_date > pr1.discharge_date` | The readmission must happen **after** the discharge (not on the same day or before) |
| `DATEDIFF(pr2.admission_date, pr1.discharge_date) <= 30` | The readmission must be **within 30 days** of the discharge |

I used `LEFT JOIN` instead of `INNER JOIN` because some discharges won't have a corresponding readmission. Those rows will have `NULL` for `readmission_date`, which is important for the final calculation.

---

### Step 2: Find the Earliest Readmission

For each discharge, there might be **multiple** admissions within the 30-day window. I used `MIN(pr2.admission_date)` to select the **earliest** readmission as the "official" one for that discharge.

---

### Step 3: Calculate the Rate

The denominator is **all discharges** (the total number of rows in the CTE). The numerator is **only those discharges that had a readmission** (where `readmission_date` is not `NULL`).

```sql
COUNT(readmission_date) / COUNT(*) * 100;
```

- ```COUNT(*)``` counts all discharges
- ```COUNT(readmission_date)``` counts only discharges with a readmission
- The division gives the percentage, and ```ROUND(..., 0)``` gives a whole number

---

## 🧩 Why I Chose This Approach

### Why a Self-Join?
A self-join allowed me to clearly **visualize the relationship** between discharges and readmissions. I could see side by side:
- The original discharge date
- The potential readmission date
- Whether they were within 30 days
This made the logic easy to verify and debug.

---

## 📊 Final Output

Executing the query in MySQL returns the readmission rate:

| thirty_day_readmission_rate |
|----------------------------------------|
| 37                                                |

*This means approximately **37%** of discharges resulted in a readmission within 30 days.

---

## 🔍 Key Takeaways

1. **Understand the business question first.** Without knowing *why* hospitals track readmission rates, it's easy to miss the context that drives the calculation.

2. **Define the "window" carefully.** The 30-day window is the core of this problem. Getting the logic right—particularly the `>` and `<=` conditions—is critical.

3. **Avoid overcounting by thinking in terms of discharges.** Each discharge opens its own 30-day window, and each readmission is tied to one specific discharge. This mental model prevents double-counting.

4. **Self-joins are powerful for comparing rows within the same table.** They allow you to filter, join, and aggregate in ways that are intuitive and easy to verify.

5. **LEFT JOIN preserves all records.** This is essential when some discharges don't have a readmission. Those `NULL` values need to be included in the denominator.

---

## 📁 Files in This Repository

- `Solutions_Data Drill #15.sql` – Contains the SQL solution
- `README.md` – This file, documenting my process and learnings

---

## 🏷️ Tags

`#SQL` `#SelfJoin` `#ReadmissionRate` `#HealthcareAnalytics` `#DataQuerying` `#DataAnalysis` `#MavenAnalytics` `#DataDrill15` `#ReadmissionRadar`

