DROP TABLE IF EXISTS userdb_feng_li_4.GC_HC_Material_MasterData;
CREATE TABLE userdb_feng_li_4.GC_HC_Material_MasterData As (
  SELECT
    Inv.MaterialCode,
    Des.name_short_description_of_product as Material_Description,
    Inv.Plant,
    valuation.company_code,
    Inv.Prod_Type,
    If (
      Inv.MaterialCode IN ("15146665", "99002089")
      AND Inv.Plant = "0386",
      "INT",
      IF(
        marc.mrp_material_requirement_planning_controller_for_the_order IN (
          "H02",
          "HS5",
          "THR",
          "H03",
          "HS1",
          "H1P",
          "H04",
          "HD1",
          "THS"
        )
        AND Inv.Prod_Type = "HALB",
        "RAW",
        IF(
          MATERIAL_GROUP_CODE = "00000069",
          "RAW",
          Inv.deriv_prod_type_code
        )
      )
    ) Material_Type,
    Inv.Country Receiving_Country,
    Inv.Subsector Category,
    Inv.base_unit,
    Inv.crncy_code,
    Inv.material_group_code,
    prod_group_name.prod_group_desc material_group_desc,
    Inv.spend_pool_high_code,
    spend1.spend_pool_high_name,
    Inv.spend_pool_med_code,
    spend2.spend_pool_med_name,
    Inv.spend_pool_low_code,
    spend3.spend_pool_low_name,
    IF(
      LENGTH(Inv.vendr_code) > 0,
      Inv.vendr_code,
      vendor.vendor_code
    ) vendor_code,
    dim.country_code vendr_country_code,
    dim.part1_name vendr_name,
    dim.city_name vendr_city,
    dim.sort_field_name vendr_and_country_name,
    marc.maintenance_status,
    marc.purchasing_group,
    marc.description_of_purchasing_group,
    marc.mrp_material_requirement_planning_type MRP_Type,
    marc.mrp_material_requirement_planning_controller_for_the_order MRP_controller,
    marc.planned_delivery_time_in_days,
    marc.goods_receipt_processing_time_in_days,
    marc.lot_size_materials_planning lot_size_key,
    marc.safety_stock,
    marc.minimum_lot_size,
    marc.rounding_value_for_purchase_order_quantity,
    marc.interval_until_next_recurring_inspection,
    marc.mrp_material_requirement_planning_group MRP_Group,
    marc.ppc_production_planning_and_control_planning_calendar planning_calendar,
    marc.planning_time_fence,
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
    ) Material_Status,
    if(
      (
        Inv.deriv_prod_type_code IN ("RAW", "INT")
        AND marc.ppc_production_planning_and_control_planning_calendar = "M1E"
      ),
      "JIT",
      if(
        uploaded_Supplier_delivery_model.delivery_model IS NOT NULL,
        uploaded_Supplier_delivery_model.delivery_model,
        "OTHERS"
      )
    ) material_delivery_model,
    marc.flag_material_for_deletion_at_plant_level,
    company.payment_method_list_val,
    company.payment_term_key_code,
    company.payment_method_supplmnt_code,
    marc.plant_specific_material_status,
    marc.procurement_type,
    marc.maximum_lot_size,
    marc.scheduling_margin_key_for_floats,
    marc.checking_group_for_availability_check,
    marc.profit_center,
    marc.issue_storage_location,
    marc.component_scrap_in_percent,
    marc.variance_key,
    marc.production_scheduling_profile
  FROM
    (
      SELECT
        substr(prod_id, 11, 8) as MaterialCode,
        plant_id as Plant,
        First(prod_type_code) as Prod_Type,
        First(plant_cntry_code) as Country,
        First(tdc_val_subsector_name) as Subsector,
        First(tdc_val_category_code) as Category,
        First(base_unit) AS base_unit,
        First(crncy_code) AS crncy_code,
        First(material_group_code) AS material_group_code,
        First(tdc_varnc_alloc_code) AS tdc_varnc_alloc_code,
        First(2sku1_alloc_ind) AS 2sku1_alloc_ind,
        First(spend_pool_high_code) AS spend_pool_high_code,
        First(spend_pool_low_code) AS spend_pool_low_code,
        First(spend_pool_med_code) AS spend_pool_med_code,
        First(mrp_drp_ctrlr_code) AS mrp_drp_ctrlr_code,
        First(suppl_netwk_prod_plant_id) AS suppl_netwk_prod_plant_id,
        Max(vendr_code) AS vendr_code,
        First(deriv_prod_type_code) AS deriv_prod_type_code,
        First(tdc_val_markup_backout_flag) AS tdc_val_markup_backout_flag,
        First(tdcval_pgp_retail_flag) AS tdcval_pgp_retail_flag
      FROM
        (
          SELECT
            *
          FROM
            dp_osi_bw_global.inventory_part_final_pq
          ORDER BY
            cal_day DESC
        )
      where
        geo_grp_name = "GREATER CHINA GROUP"
        and tdc_val_subsector_name LIKE "%HAIR%" --and tdc_val_category_code="HAIRCARE"
        and prod_type_code IN ("ROH", "HALB")
        AND plant_id in ("0386", "A868", "1864", "9264")
      GROUP BY
        substr(prod_id, 11, 8),
        plant_id
    ) Inv
    left join (
      select
        substr(id_of_product_material, 11, 8) material_number,
        name_short_description_of_product
      from
        dp_osi_ap_ecc.makt_material_descriptions
      where
        language_code = "E"
    ) as Des on Inv.MaterialCode = Des.material_number
    left join (
      select
        marc1.*,
        t024.description_of_purchasing_group,
        t024.telephone_number_of_purchasing_group_buyer_group,
        t024.spool_output_device,
        t024.telephone_no_dialling_code_number
      FROM
        dp_osi_ap_ecc.marc_plant_data_for_material marc1
        left join dp_masterdata_g11.t024_purchasing_groups t024 on marc1.purchasing_group = t024.purchasing_group
    ) MARC on Inv.MaterialCode = substr(marc.id_of_product_material, 11, 8)
    and Inv.Plant = marc.plant_id
    left join (
      SELECT
        spend_pool_high_code,
        FIRST(spend_pool_high_name) as spend_pool_high_name
      FROM
        dp_osi_bw_global.spend_pool_hier_final_pq
      GROUP BY
        spend_pool_high_code
    ) spend1 on Inv.spend_pool_high_code = spend1.spend_pool_high_code
    left join (
      SELECT
        spend_pool_med_code,
        FIRST(spend_pool_med_name) as spend_pool_med_name
      FROM
        dp_osi_bw_global.spend_pool_hier_final_pq
      GROUP BY
        spend_pool_med_code
    ) spend2 on Inv.spend_pool_med_code = spend2.spend_pool_med_code
    left join (
      SELECT
        spend_pool_low_code,
        FIRST(spend_pool_low_name) as spend_pool_low_name
      FROM
        dp_osi_bw_global.spend_pool_hier_final_pq
      GROUP BY
        spend_pool_low_code
    ) spend3 on Inv.spend_pool_low_code = spend3.spend_pool_low_code
    left join (
      SELECT
        *
      from
        dp_masterdata_g11.prod_group_desc_lkp
      where
        lang_code = "E"
    ) prod_group_name on Inv.material_group_code = prod_group_name.prod_group_name
    left join dp_masterdata_g11.t001k_valuation_area valuation on Inv.Plant = valuation.site_plant_code
    left join (
      SELECT
        plant_id,
        prod_id,
        FIRST(vendor_account_number) vendor_code
      FROM
        (
          SELECT
            EKPO.purchase_order_number,
            EKPO.purchasing_document_item_change_date,
            EKPO.plant_id,
            substr(EKPO.id_of_product_material, 11, 8) prod_id,
            EKKO.vendor_account_number
          FROM
            dp_osi_ap_ecc.ekpo_purchasing_document_item EKPO
            LEFT JOIN dp_osi_ap_ecc.ekko_purchasing_document_header EKKO ON EKPO.purchase_order_number = EKKO.purchasing_document_number --WHERE EKPO.purchasing_document_item_change_date IS NOT NULL
          ORDER BY
            EKPO.purchasing_document_item_change_date DESC
        )
      GROUP BY
        plant_id,
        prod_id
    ) vendor ON Inv.MaterialCode = vendor.prod_id
    AND Inv.Plant = vendor.plant_id
    left join dp_masterdata_g11.vendor_dim dim on IF(
      LENGTH(Inv.vendr_code) > 0,
      Inv.vendr_code,
      vendor.vendor_code
    ) = dim.vendor_id
    left join dp_masterdata_g11.vendor_company_code_dim company on IF(
      LENGTH(Inv.vendr_code) > 0,
      Inv.vendr_code,
      vendor.vendor_code
    ) = company.vendor_id
    and valuation.company_code = company.company_code
    left join userdb_feng_li_4.uploaded_Supplier_delivery_model on substr(
      IF(
        LENGTH(Inv.vendr_code) > 0,
        Inv.vendr_code,
        vendor.vendor_code
      ),
      3,
      8
    ) = uploaded_Supplier_delivery_model.vendor_code
    AND Inv.Plant = uploaded_Supplier_delivery_model.plant_id
)