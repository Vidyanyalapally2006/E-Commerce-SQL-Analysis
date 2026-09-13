# E-Commerce Sales & Customer Analytics using SQL

## 📌 Project Overview

This project analyzes Brazilian e-commerce sales data using **MySQL** to uncover business insights related to customers, products, categories, sellers, regions, and sales growth.

The analysis is based on the **Brazilian E-Commerce Public Dataset by Olist**, containing approximately 100K orders and multiple interconnected datasets.

The project demonstrates practical SQL skills including:

- Data exploration
- Multi-table joins
- Aggregations
- Common Table Expressions (CTEs)
- Window functions
- Customer segmentation
- Revenue analysis
- Time-series analysis
- Business-driven SQL analysis

---

## 🎯 Business Objectives

The main objectives of this project are to:

- Understand overall e-commerce performance
- Identify high-value and repeat customers
- Analyze customer purchasing behavior
- Identify top-performing product categories
- Evaluate seller performance
- Analyze regional sales patterns
- Measure monthly and yearly revenue growth
- Identify revenue concentration
- Answer practical business questions using SQL
- Generate actionable business recommendations

---

## 🗂️ Dataset

**Dataset:** Brazilian E-Commerce Public Dataset by Olist

Source:

https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

The dataset contains information about:

- Customers
- Orders
- Products
- Sellers
- Order items
- Payments
- Reviews
- Geolocation
- Product category translations

---

## 🛠️ Technologies Used

- **MySQL**
- SQL
- MySQL Workbench
- Git
- GitHub

### SQL Concepts Used

- SELECT
- WHERE
- GROUP BY
- HAVING
- ORDER BY
- JOIN
- LEFT JOIN
- CASE
- Aggregate functions
- Subqueries
- CTEs
- Window functions
- RANK()
- DENSE_RANK()
- ROW_NUMBER()
- LAG()
- LEAD()
- NTILE()
- Running totals
- Revenue contribution analysis
- Time-series analysis

---

## 📁 Project Structure

```text
E-Commerce-SQL-Analysis/
│
├── data/
│   └── Olist CSV datasets
│
├── sql/
│   ├── 01_data_exploration.sql
│   ├── 02_advanced_analysis.sql
│   ├── 03_customer_analytics.sql
│   ├── 04_product_category_analysis.sql
│   ├── 05_seller_regional_analysis.sql
│   ├── 06_time_series_analysis.sql
│   └── 07_business_questions.sql
│
├── reports/
│   └── final_business_report.pdf
│
├── .gitignore
└── README.md