DROP TABLE IF EXISTS userdb_feng_li_4.GC_HC_FP_Planning_Parameter;
CREATE TABLE userdb_feng_li_4.GC_HC_FP_Planning_Parameter As(
  SELECT
    substr(marc.id_of_product_material, 11, 8) prod_id,
    makt2.prod_name,
    mara2.prod_type prod_type,
    if(
      (
        marc.mrp_material_requirement_planning_type = "ND"
        OR marc.flag_material_for_deletion_at_plant_level = "X"
      ),
      "Inactive",
      if(
        length(marc.mrp_material_requirement_planning_type) < 2,
        "Inactive",
        "Active"
      )
    ) Prod_Status,
    marc.plant_id,
    plant.part1_name plant_name,
    plant.city_name plant_city_name,
    company.company_code,
    idp.product_brand_name Brand,
    IF(
      Inv.Category IS NULL,
      prod.prod_4_name,
      Inv.Category
    ) Category,
    marc.mrp_material_requirement_planning_type MRP_Type,
    marc.mrp_material_requirement_planning_controller_for_the_order MRP_controller,
    marc.lot_size_materials_planning lot_size_key,
    marc.safety_time_in_workdays safety_time,
    marc.safety_stock,
    marc.maximum_stock_level,
    marc.minimum_lot_size MOQ,
    marc.rounding_value_for_purchase_order_quantity rounding_value,
    mara2.base_unit_of_measure,
    marc.planned_delivery_time_in_days PDT_time,
    marc.goods_receipt_processing_time_in_days GR_time,
    marc.planning_time_fence,
    --marc.planning_cycle,
    --marc.interval_until_next_recurring_inspection shelf_life,
    marc.mrp_material_requirement_planning_group MRP_Group --marc.ppc_production_planning_and_control_planning_calendar planning_calendar,
    --marc.indicator_for_material_apo_advanced_planning_and_optimization_exclusion
  FROM
    dp_osi_ap_ecc.marc_plant_data_for_material marc
    Left join dp_demand_forecast_idp.asia_product_dim idp on marc.id_of_product_material = idp.product_id
    LEFT JOIN dp_direct_shpmt_cfr.shpmt_prod_5005_day_fdim prod ON substr(marc.id_of_product_material, 11, 8) = prod.prod_id
    left join (
      SELECT
        id_of_product_material,
        FIRST(TYPE_OF_PRODUCT_SETUP_IN_SAP) as prod_type,
        FIRST(base_unit_of_measure) base_unit_of_measure
      FROM
        dp_masterdata_g11.mara_general_material_data
      GROUP BY
        id_of_product_material
    ) mara2 on marc.id_of_product_material = mara2.id_of_product_material
    left join (
      SELECT
        id_of_product_material,
        name_short_description_of_product as prod_name
      FROM
        dp_masterdata_g11.makt_material_descriptions
      WHERE
        language_code = "E"
    ) makt2 on marc.id_of_product_material = makt2.id_of_product_material
    left join (
      SELECT
        substr(prod_id, 11, 8) as MaterialCode,
        First(tdc_val_subsector_name) as Category
      FROM
        dp_osi_bw_global.inventory_part_final_pq
      group by
        substr(prod_id, 11, 8)
    ) Inv on substr(marc.id_of_product_material, 11, 8) = Inv.MaterialCode
    LEFT JOIN dp_masterdata_g11.t001k_valuation_area company ON marc.plant_id = company.site_plant_code
    LEFT JOIN DP_MASTERDATA_G11.plant_dim plant ON marc.plant_id = plant.plant_id
  WHERE
    company.company_code IN ("293", "2294", "2273") --AND marc.plant_id in ("0386","A868","1864","9264","A684","A685","A727","A743")
    AND mara2.prod_type = "FERT"
    AND (
      UPPER(Inv.Category) LIKE "%HAIR%"
      OR UPPER(prod.prod_4_name) LIKE "%HAIR%"
      OR idp.product_brand_name IN (
        "VIDALSASON",
        "HD&SHLDRS",
        "PANTENE",
        "HAIRRECIPE",
        "REJOICE",
        "PERT",
        "HERBALESSR",
        "AUSSIER"
      )
      OR makt2.prod_name LIKE "HS %"
      OR makt2.prod_name LIKE "% HS %"
      OR (
        makt2.prod_name LIKE "%H&S%"
        AND (NOT makt2.prod_name LIKE "%SFG%")
      )
      OR makt2.prod_name LIKE "%RJC %"
      OR makt2.prod_name LIKE "%REJ %"
      OR UPPER(makt2.prod_name) LIKE "%REJOICE%"
      OR (
        makt2.prod_name LIKE "%PTN %"
        AND (NOT makt2.prod_name LIKE "OLAY%")
      )
      OR makt2.prod_name LIKE "%PNT %"
      OR makt2.prod_name LIKE "%PANTENE%"
      OR makt2.prod_name LIKE "%VS %"
      OR makt2.prod_name LIKE "%VIDALSASON%"
      OR makt2.prod_name LIKE "%AUSSIE%"
      OR makt2.prod_name LIKE "AU %"
      OR makt2.prod_name LIKE "% AU %"
      OR makt2.prod_name LIKE "HERBA%"
      OR makt2.prod_name LIKE "%HESS%"
      OR (
        makt2.prod_name LIKE "% HERBA%"
        AND (NOT makt2.prod_name LIKE "ARIEL%")
        AND (NOT makt2.prod_name LIKE "CR%")
        AND (NOT makt2.prod_name LIKE "OR%")
        AND (NOT makt2.prod_name LIKE "CS%")
        AND (NOT makt2.prod_name LIKE "%CREST %")
        AND (NOT makt2.prod_name LIKE "OB%")
      )
      OR makt2.prod_name LIKE "PERT %"
      OR makt2.prod_name LIKE "% PERT %"
      OR makt2.prod_name LIKE "HR %"
      OR makt2.prod_name LIKE "% HR %"
      OR makt2.prod_name LIKE "%HAIRRECIPE%"
      OR makt2.prod_name LIKE "%SHM%"
      OR (
        makt2.prod_name LIKE "%COND%"
        AND (NOT makt2.prod_name LIKE "%SFG%")
      )
      OR makt2.prod_name LIKE "%STYLING%"
    )
    AND NOT Inv.Category IN (
      "ORALCARE",
      "PROFSALON",
      "APPLIANCES",
      "SKINPERSCR",
      "DISCSNACKS",
      "COSMETICS",
      "Discontinued Prestige",
      "PRESTIGE",
      "SHAVECARE",
      "FABRICCARE",
      "CORPINVFND",
      "ZINCTVHCLR",
      "FEMCARE"
    )
    AND NOT Inv.Category LIKE "%Discontinued%Cosmetics%"
    AND NOT Inv.Category LIKE "%Discontinued%Professional%Salon%"
    AND NOT Inv.Category LIKE "%Oral%Care%"
    AND NOT Inv.Category LIKE "%Skin%and%Personal%"
)