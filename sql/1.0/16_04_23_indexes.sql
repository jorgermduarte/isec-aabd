-- ======================================================================
-- ============ 		 						 		 ================
-- ============ 		 INDEXES CREATION SCRIPT 		 ================
-- ============ 		 						 		 ================
-- ======================================================================

CREATE INDEX idx_client_full_name ON client(full_name);

CREATE INDEX idx_client_nif ON client(nif);

CREATE INDEX idx_client_status_type ON client(status_type);

CREATE INDEX idx_plan_name ON plan(name);

CREATE INDEX idx_plan_status_type ON plan(status_type);

CREATE INDEX idx_plan_plan_type ON plan(plan_type);

CREATE INDEX idx_contract_id_client ON contract(id_client);

CREATE INDEX idx_contract_id_plan ON contract(id_plan);

CREATE INDEX idx_contract_start_date ON contract(start_date);

CREATE INDEX idx_tarrif_id_plan ON tarrif(id_plan);

CREATE INDEX idx_tarrif_status ON tarrif(status);

CREATE INDEX idx_notification_id_client ON notification(id_client);

CREATE INDEX idx_invoice_id_contract ON invoice(id_contract);

CREATE INDEX idx_bundle_id_contract ON bundle(id_contract);

CREATE INDEX idx_bundle_package_type ON bundle(package_type);

CREATE INDEX idx_bundle_package_network ON bundle(package_network);

CREATE INDEX idx_bundle_status ON bundle(status);
