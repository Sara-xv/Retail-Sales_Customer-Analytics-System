# Retail Intelligence & Business Performance Analysis

### Sales, Profitability, and Returns Analytics Using SQL Server

![SQL Server](https://img.shields.io/badge/SQL%20Server-T--SQL-14284b)
![Type](https://img.shields.io/badge/Project-Business%20Intelligence-14284b)
![Data](https://img.shields.io/badge/Data-Synthetic-5a6882)

## Table of Contents

1. [Organization Overview](#1-organization-overview)
2. [Business Problem](#2-business-problem)
3. [Project Objectives](#3-project-objectives)
4. [Scope of Analysis](#4-scope-of-analysis)
5. [Key Performance Indicators](#5-key-performance-indicators)
6. [Key Findings](#6-key-findings)
7. [Data Quality & Analytical Reliability](#7-data-quality--analytical-reliability)
8. [Business Recommendations](#8-business-recommendations)
9. [Business Value](#9-business-value)
10. [Conclusion](#10-conclusion)

## 1. Organization Overview

**Organization:** Northstar Retail Group  
**Industry:** Retail & Consumer Goods  
**Business Model:** Omnichannel Retail — Online and Physical Stores

Northstar Retail Group is a fictional retail organization operating through online and physical sales channels. The company offers products across multiple retail categories, including Clothing, Footwear, and Accessories.

As the business grows, management needs a clearer understanding of sales performance, profitability, product demand, and customer return behavior. Transactional data provides an opportunity to identify performance trends, investigate operational challenges, and support evidence-based business decisions.

This project simulates a business intelligence engagement designed to help Northstar Retail Group turn retail transaction data into actionable insights.

## 2. Business Problem

Retail organizations must balance revenue growth, profitability, customer satisfaction, and operational efficiency. Strong sales performance alone does not necessarily indicate healthy business performance, particularly when product returns and refunds create additional operational and financial exposure.

Northstar Retail Group faces several analytical questions:

- Which products and categories contribute most to sales and profitability?
- How do sales and profit margins vary across products, channels, and time periods?
- What proportion of sold units are returned?
- Which return reasons account for the greatest number of returned units and refunds?
- Do return rates differ across product categories and sales channels?
- Which products warrant further investigation because of elevated return rates?
- What actions could improve operational efficiency and support more informed decisions?

The objective is to answer these questions through structured SQL analysis rather than relying on assumptions or isolated performance metrics.

## 3. Project Objectives

The project has two primary analytical workstreams.

### A. Sales & Profitability Analysis

- Evaluate overall sales performance and sales volume.
- Analyze revenue, gross profit, and gross margin.
- Compare performance across product categories and individual products.
- Examine sales channel performance and temporal trends.
- Identify products and categories that may represent growth or profitability opportunities.
- Translate observed patterns into business recommendations.

### B. Returns Analysis

- Measure total returned units, return events, and recorded refund amounts.
- Calculate the overall unit return rate.
- Compare return rates by original sales year and product category.
- Investigate return reasons and their contribution to return volume and refunds.
- Compare return performance across online and in-store sales channels.
- Identify products with relatively high unit return rates.
- Validate key relationships and quantity constraints to improve analytical reliability.

## 4. Scope of Analysis

The analysis covers the following business dimensions:

| Business Area | Analytical Focus |
|---|---|
| Sales Performance | Sales volume, revenue, and trends |
| Profitability | Gross profit and gross margin |
| Product Analysis | Product-level and category-level performance |
| Channel Analysis | Online versus physical-store performance |
| Returns Performance | Returned units and unit return rates |
| Return Reasons | Return frequency, quantity, and refund exposure |
| Data Quality | Relationship integrity and returned-quantity validation |

The analysis uses a dimensional data model containing sales and returns fact tables supported by product, date, customer, store, channel, and return-reason dimensions.

## 5. Key Performance Indicators

The project uses business-focused metrics to evaluate performance.

**Sales & Profitability KPIs**

- Total Sales Revenue
- Total Gross Profit
- Gross Profit Margin
- Units Sold
- Product and Category Performance

**Returns KPIs**

- Total Return Events
- Total Returned Units
- Unit Return Rate
- Total Recorded Refund Amount
- Return-Event Share by Reason
- Unit Return Rate by Product Category
- Unit Return Rate by Sales Channel
- Product-Level Unit Return Rate

The unit return rate is calculated as total returned units divided by total sold units. It should not be confused with the percentage of orders containing returns or the percentage of sales value refunded.

## 6. Key Findings

### Overall Returns Performance

The dataset contains 1,040,000 sold units and 37,665 returned units, producing an overall unit return rate of **3.62%**. Recorded refunds total approximately **17.78 billion dataset monetary units**.

### Annual Return Trends

The unit return rate by original sales year declined from 3.95% in 2023 to 3.50% in 2024 and 3.41% in 2025.

This pattern may warrant further investigation. However, differences in the time available for customers to return purchases mean that the observed decline should not automatically be interpreted as a sustained improvement in product quality or customer satisfaction.

### Product Category Performance

Accessories recorded the highest unit return rate at 3.70%, compared with 3.62% for both Clothing and Footwear.

Clothing accounted for the largest refund amount, reflecting its substantially greater sales volume. This distinction illustrates why return rates and total financial exposure should be evaluated together.

### Return Reasons

Wrong Item was associated with 9,913 returned units and approximately 4.65 billion monetary units in refunds, the highest totals among the five recorded return reasons.

Defective products accounted for 7,931 returned units and approximately 3.83 billion monetary units in refunds.

These findings identify order accuracy and product quality as useful areas for further operational investigation.

### Sales Channel Performance

Online sales recorded a unit return rate of 3.63%, while in-store sales recorded 3.62%.

The difference is only 0.01 percentage points, providing no strong evidence that either channel has a meaningfully higher return rate based on the current aggregate results.

### Product-Level Return Performance

The ten products with the highest observed unit return rates, subject to a minimum sales-volume threshold, all recorded a rate of 4.58%.

Because these products shared identical sales and return quantities, the ranking alone does not establish which product has the greatest underlying issue. Additional analysis of return reasons and product characteristics would be needed.

## 7. Data Quality & Analytical Reliability

Several validation checks were performed before interpreting the results:

- No return records without a matching sales line were identified.
- No non-positive return quantities were identified.
- No negative refund amounts were identified.
- No individual or cumulative returned quantities exceeded the corresponding sold quantities.

Return quantities and refund amounts were aggregated at the original sales-line level before being joined to sales data. This approach helps prevent double counting when multiple return records relate to the same sales line.

These checks support confidence in the calculations covered by the validation process, although they do not guarantee that every source record is error-free.

## 8. Business Recommendations

### Improve Order Fulfillment Accuracy

Investigate Wrong Item returns to identify potential issues in picking, packing, product identification, or order fulfillment.

### Investigate Product Quality

Review Defective returns by product and category to identify recurring patterns that may justify quality-control improvements.

### Examine Product-Specific Return Drivers

Analyze the return reasons associated with products that have relatively high return rates. This can help distinguish sizing issues, product defects, incorrect fulfillment, and differences between customer expectations and the delivered product.

### Monitor Returns Alongside Sales Performance

Evaluate return rates together with sales volume, refund exposure, and profitability. High sales volume and high return rates represent different business risks and require different responses.

### Use Comparable Time Periods

When comparing annual return rates, account for the time available for purchases to generate returns. Mature sales cohorts provide a more reliable basis for comparison than recent cohorts with incomplete return exposure.

### Track Channel Performance Over Time

Since online and in-store return rates are nearly identical in the current aggregate data, monitor their evolution over time before prioritizing channel-specific interventions.

## 9. Business Value

This project demonstrates how transactional retail data can support business decisions beyond basic sales reporting.

By combining sales, profitability, and returns analysis, the organization can develop a more balanced view of commercial performance, identify areas for operational investigation, and establish a foundation for ongoing KPI monitoring.

The results also demonstrate the importance of reliable metric definitions, appropriate aggregation, data validation, and careful interpretation of analytical findings.

## 10. Conclusion

The Retail Intelligence project applies SQL-based analysis to a simulated omnichannel retail business, covering sales performance, profitability, product behavior, and product returns.

The analysis identifies opportunities to investigate order fulfillment accuracy, product quality, category-level return patterns, and product-specific return drivers. It also highlights the importance of comparing return rates alongside sales volumes and accounting for differences in return exposure over time.

The overall goal is to transform raw retail transactions into meaningful business insights that support better operational decisions and more informed performance management.

---

**Project Type:** Retail Business Intelligence & Analytics  
**Organization:** Northstar Retail Group *(fictional case study)*  
**Technology:** Microsoft SQL Server / T-SQL  
**Currency:** Unspecified dataset monetary units
