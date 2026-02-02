/*
Портфолио-версия витрины plan_fact.

Цель:
Подготовка агрегированных данных для план-факт аналитики,
используемой в BI-дашбордах и регулярной отчетности.

Данные агрегируются по:
- месяцу
- менеджеру
- группе продукта

Названия схем и таблиц являются условными и применяются только для демонстрации подходов к аналитике данных.
*/

CREATE OR REPLACE VIEW analytics.plan_fact AS

-- 1. Агрегация фактических продаж
WITH fact_sales AS (
    SELECT
        date_trunc('month', sale_date)::date AS month, -- Приведение даты к месяцу
        manager_id, -- Идентификатор менеджера
        product_group, -- Группа продукта
        -- Фактические показатели
        SUM(quantity) AS fact_qty,
        SUM(amount) AS fact_sum
    FROM analytics.sales
    GROUP BY
        month,
        manager_id,
        product_group
),

-- 2. Агрегация плановых показателей
plan_sales AS (
    SELECT
        date_trunc('month', plan_date)::date AS month, -- Приведение даты к месяцу
        manager_id, -- Идентификатор менеджера
        product_group, -- Группа продукта
        -- Плановые показатели
        SUM(planned_qty) AS plan_qty,
        SUM(planned_sum) AS plan_sum
    FROM analytics.plan
    GROUP BY
        month,
        manager_id,
        product_group
)

-- 3. Объединение плана и факта в единую витрину
SELECT
    COALESCE(p.month, f.month) AS month, -- Месяц аналитики
    COALESCE(p.manager_id, f.manager_id) AS manager_id, -- Менеджер
    COALESCE(p.product_group, f.product_group) AS product_group, -- Группа продукта
    -- План
    p.plan_qty,
    p.plan_sum,
    -- Факт
    f.fact_qty,
    f.fact_sum,

    -- Отклонения (могут использоваться в BI)
    f.fact_qty - p.plan_qty AS qty_deviation,
    f.fact_sum - p.plan_sum AS sum_deviation

FROM plan_sales p

-- FULL JOIN используется для сохранения строк,
-- где есть только план или только факт
FULL JOIN fact_sales f
    ON f.month = p.month
   AND f.manager_id = p.manager_id
   AND f.product_group = p.product_group;
