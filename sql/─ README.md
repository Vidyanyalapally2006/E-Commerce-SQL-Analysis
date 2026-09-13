# E-Commerce Sales & Customer Analytics using SQL

## 📌 Project Overview

This project analyzes an e-commerce dataset to uncover meaningful insights about sales performance, customers, products, categories, sellers, regions, and business growth.

The analysis was performed using **MySQL** with advanced SQL techniques including:

- Multi-table joins
- Common Table Expressions (CTEs)
- Aggregate functions
- Subqueries
- Window functions
- Ranking
- Running totals
- Month-over-month growth
- Year-over-year growth
- Customer segmentation
- Revenue contribution analysis

The goal of this project is to demonstrate how SQL can be used to transform raw transactional data into actionable business insights.

---

## 🎯 Business Objectives

The analysis focuses on answering questions such as:

- How is overall sales performance?
- Which product categories generate the most revenue?
- Which customers contribute the most revenue?
- How important are repeat customers?
- Which sellers perform best?
- Which regions generate the most sales?
- What percentage of revenue comes from cross-state transactions?
- Which categories are growing or declining?
- How concentrated is revenue among customers and sellers?
- How has the business performed over time?

---

## 📊 Dataset

The project uses the **Brazilian E-Commerce Public Dataset by Olist**.

Dataset source:

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
- Product categories

---

## 🗂️ Database Schema

The analysis uses the following tables:

| Table | Description |
|---|---|
| `customers` | Customer information and location |
| `orders` | Order-level information and timestamps |
| `products` | Product details and categories |
| `sellers` | Seller information and location |
| `order_items` | Products purchased within each order |
| `order_payments` | Payment information |
| `order_reviews` | Customer review information |
| `geolocation` | Brazilian geographic information |
| `category_translation` | Portuguese-to-English category mapping |

---

## 🛠️ Technologies Used

- **MySQL**
- SQL
- MySQL Workbench
- Git & GitHub
- Kaggle Dataset

---

## 📁 Project Structure

```text
E-Commerce-SQL-Analysis/
│
├── data/
│   ├── olist_customers_dataset.csv
│   ├── olist_geolocation_dataset.csv
│   ├── olist_order_items_dataset.csv
│   ├── olist_order_payments_dataset.csv
│   ├── olist_order_reviews_dataset.csv
│   ├── olist_orders_dataset.csv
│   ├── olist_products_dataset.csv
│   ├── olist_sellers_dataset.csv
│   └── product_category_name_translation.csv
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
└── README.md