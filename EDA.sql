USE ecommerce_funnel_db;

select * from cleaned_funnel_data;

-- Q1. Where exactly do users drop off and by how much?

WITH funnel_counts AS (
    SELECT 'Visited Site' AS stage, SUM(visited_site) AS users FROM cleaned_funnel_data
    UNION ALL
    SELECT 'Viewed Product', SUM(viewed_product) FROM cleaned_funnel_data
    UNION ALL
    SELECT 'Added to Cart', SUM(added_to_cart) FROM cleaned_funnel_data
    UNION ALL
    SELECT 'Initiated Checkout', SUM(initiated_checkout) FROM cleaned_funnel_data
    UNION ALL
    SELECT 'Completed Purchase', SUM(completed_purchase) FROM cleaned_funnel_data
),
drop_analysis AS (
    SELECT
        stage,
        users,
        LAG(users) OVER (ORDER BY users DESC) AS prev_stage_users
    FROM funnel_counts
)
SELECT
    stage,
    users,
    ROUND((prev_stage_users - users)*100.0/prev_stage_users,2) AS drop_off_percentage
FROM drop_analysis;

-- Insight : Maximum drop happens before Add to Cart. Product pages are the highest leverage point

-- Q2. Stage-to-stage conversion rate
WITH FunnelStages AS (
    SELECT 
        COUNT(DISTINCT session_id) AS total_sessions,
        SUM(viewed_product) AS total_views,
        SUM(added_to_cart) AS total_adds,
        SUM(initiated_checkout) AS total_checkouts,
        SUM(completed_purchase) AS total_purchases
    FROM cleaned_funnel_data
)
SELECT 
    total_sessions,
    -- Calculate % of users reaching each stage from the start
    ROUND(100.0 * total_views / total_sessions, 2) AS session_to_view_pct,
    ROUND(100.0 * total_adds / total_views, 2) AS view_to_cart_pct,
    ROUND(100.0 * total_checkouts / total_adds, 2) AS cart_to_checkout_pct,
    ROUND(100.0 * total_purchases / total_checkouts, 2) AS checkout_to_purchase_pct,
    -- Overall Conversion Rate
    ROUND(100.0 * total_purchases / total_sessions, 2) AS overall_cr
FROM FunnelStages;





-- Q3. How much revenue is lost because users abandon carts or checkout?
SELECT
    ROUND(SUM(cart_value),2) AS potential_revenue,
    ROUND(SUM(CASE WHEN completed_purchase = 1 THEN revenue ELSE 0 END),2) AS realized_revenue,
    ROUND(SUM(cart_value) - SUM(CASE WHEN completed_purchase = 1 THEN revenue ELSE 0 END),2)
        AS revenue_leakage
FROM cleaned_funnel_data;
-- Insight : Highlights direct monetary loss, Justifies retargeting & checkout optimization


-- Q4. Traffic Source Performance (Revenue & Conversion) 
SELECT 
    traffic_source,
    COUNT(*) as total_sessions,
    SUM(viewed_product) as viewed,
    SUM(completed_purchase) as purchased,
    ROUND(SUM(completed_purchase) * 100.0 / COUNT(*), 2) as conversion_rate
FROM cleaned_funnel_data
GROUP BY traffic_source
ORDER BY conversion_rate DESC;
-- Insight - Helps decide which marketing channels deserve more budget.


-- Q5. Performace per product category
SELECT
    product_category,
    COUNT(*) AS sessions,
    SUM(completed_purchase) AS purchases,
    ROUND(SUM(completed_purchase) * 100.0 / COUNT(*), 2) AS conversion_rate,
    ROUND(SUM(revenue),2) AS total_revenue
FROM cleaned_funnel_data
GROUP BY product_category
ORDER BY total_revenue DESC;
-- Insights : Enables inventory & promotion prioritization


-- Q6. High Intent sessions 
SELECT
    CASE
        WHEN session_duration_sec < 60 THEN 'Low Intent'
        WHEN session_duration_sec BETWEEN 60 AND 300 THEN 'Medium Intent'
        ELSE 'High Intent'
    END AS session_quality,
    COUNT(*) AS sessions,
    ROUND(SUM(completed_purchase)*100.0/COUNT(*),2) AS conversion_rate
FROM cleaned_funnel_data
GROUP BY session_quality;

  
  
-- Q7. Best Performing Time Windows
SELECT
    day_name,
    hour_of_day,
    COUNT(*) AS sessions,
    SUM(completed_purchase) AS purchases,
    ROUND(SUM(revenue),2) AS revenue
FROM cleaned_funnel_data
GROUP BY day_name, hour_of_day
ORDER BY revenue DESC
LIMIT 10;
-- Insights : Useful for ad scheduling & flash sales


-- Q8. 
SELECT
    is_bounce,
    COUNT(*) AS sessions,
    SUM(completed_purchase) AS purchases
FROM cleaned_funnel_data
GROUP BY is_bounce;
-- Insights: Validates landing page optimization importance




