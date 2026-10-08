WITH facebook_data AS (
    SELECT
        fabd.ad_date,
        fabd.url_parameters,
        'facebook' AS source,
        fc.campaign_name,
        fa.adset_name,
        fabd.spend,
        fabd.impressions,
        fabd.reach,
        fabd.clicks,
        fabd.leads,
        fabd.value
    FROM public.facebook_ads_basic_daily fabd
    LEFT JOIN public.facebook_campaign fc ON fabd.campaign_id = fc.campaign_id
    LEFT JOIN public.facebook_adset fa ON fabd.adset_id = fa.adset_id
),
google_data AS (
    SELECT
        ad_date,
        url_parameters,
        'google' AS source,
        campaign_name,
        adset_name,
        spend,
        impressions,
        reach,
        clicks,
        leads,
        value
    FROM public.google_ads_basic_daily
),
all_ads_data AS (
    SELECT * FROM facebook_data
    UNION ALL
    SELECT * FROM google_data
),
prepared_data AS (
    SELECT
        ad_date,
        source,
        campaign_name,
        adset_name,
        CASE 
            WHEN substring(url_parameters from 'utm_campaign=([^&]+)') IS NULL THEN NULL
            WHEN LOWER(substring(url_parameters from 'utm_campaign=([^&]+)')) = 'nan' THEN NULL
            ELSE public.decode_url_part(LOWER(substring(url_parameters from 'utm_campaign=([^&]+)')))
        END AS utm_campaign,
        spend,
        impressions,
        reach,
        clicks,
        leads,
        value
    FROM all_ads_data
)
SELECT
    ad_date,
    source,
    campaign_name,
    adset_name,
    utm_campaign,
    SUM(COALESCE(spend, 0)) AS total_spend,
    SUM(COALESCE(impressions, 0)) AS total_impressions,
    SUM(COALESCE(reach, 0)) AS total_reach,
    SUM(COALESCE(clicks, 0)) AS total_clicks,
    SUM(COALESCE(leads, 0)) AS total_leads,
    SUM(COALESCE(value, 0)) AS total_value
FROM prepared_data
GROUP BY 1, 2, 3, 4, 5
order by ad_date asc;