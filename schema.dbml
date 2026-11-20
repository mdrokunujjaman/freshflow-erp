// ==============================================================================
// FreshFlow ERP — Unified Database Schema & DBML Specification
// Docs: https://dbml.dbdiagram.io/docs
// ==============================================================================

// ─── 1. Authentication & RBAC ────────────────────────────────────────────────

Table users {
  id integer [primary key, increment]
  username varchar(150) [unique, not null]
  email varchar(254)
  first_name varchar(150)
  last_name varchar(150)
  role varchar(20) [not null, default: 'RESTAURANT_CLIENT', note: 'ADMIN | WAREHOUSE_MANAGER | SALES_AGENT | RESTAURANT_CLIENT']
  phone_number varchar(20)
  is_active boolean [not null, default: true]
  is_staff boolean [not null, default: false]
  is_superuser boolean [not null, default: false]
  last_login timestamp
  date_joined timestamp [not null]

  indexes {
    role
  }
}

// ─── 2. Workforce & Human Resources ──────────────────────────────────────────

Table departments {
  id integer [primary key, increment]
  name varchar(100) [unique, not null]
  code varchar(20) [unique, not null, note: 'e.g. WH-LOG, SALES, OPS, EXEC']
  description text
  is_active boolean [not null, default: true]
  created_at timestamp [not null]
  updated_at timestamp [not null]
}

Table employee_profiles {
  id integer [primary key, increment]
  user_id integer [unique, not null]
  employee_id varchar(30) [unique, not null, note: 'Company code, e.g. FF-WH-0024']
  profile_picture varchar(100)
  
  // Category A: Administrator-Controlled Employment Info
  official_full_name varchar(150)
  company_email varchar(254)
  department_id integer
  designation varchar(100) [not null, default: 'Staff']
  employment_type varchar(30) [not null, default: 'FULL_TIME', note: 'FULL_TIME | PART_TIME | CONTRACT | PROBATION | INTERN']
  employment_status varchar(30) [not null, default: 'ACTIVE', note: 'ACTIVE | ON_LEAVE | SUSPENDED | TERMINATED']
  date_of_joining date
  reporting_manager_id integer
  work_location varchar(150) [default: 'Dhaka Warehouse (Main)']
  shift_schedule varchar(100) [default: 'Day Shift (9:00 AM – 6:00 PM)']
  salary_grade varchar(50) [default: 'Grade 2 (Operations)']

  // Category B: Employee-Editable Personal Info
  personal_email varchar(254)
  personal_phone varchar(30)
  date_of_birth date
  gender varchar(20) [default: 'Male']
  national_id varchar(50)
  address text
  emergency_contact_name varchar(100)
  emergency_contact_phone varchar(30)
  blood_group varchar(10) [default: 'B+']
  marital_status varchar(20) [default: 'Married']
  nationality varchar(50) [default: 'Bangladeshi']
  preferred_language varchar(100) [default: 'English, Bangla']

  // Category C: Audit Metadata
  created_by_id integer
  created_at timestamp [not null]
  updated_at timestamp [not null]

  indexes {
    employment_status
  }
}

Table employment_histories {
  id integer [primary key, increment]
  employee_id integer [not null]
  field_name varchar(50) [not null]
  old_value text
  new_value text
  changed_by_id integer
  reason text
  created_at timestamp [not null]
}

Table audit_logs {
  id integer [primary key, increment]
  actor_id integer
  target_user_id integer
  action varchar(100) [not null, note: 'e.g. USER_LOGIN, BATCH_STATUS_CHANGE']
  category varchar(50) [not null, note: 'AUTH | PROFILE | EMPLOYMENT | INVENTORY | ORDERS | SECURITY']
  description text [not null]
  resource_type varchar(50)
  resource_id varchar(50)
  metadata json
  ip_address varchar(45)
  user_agent varchar(255)
  created_at timestamp [not null]

  indexes {
    action
    category
    created_at
  }
}

// ─── 3. CRM & B2B Client Governance ──────────────────────────────────────────

Table restaurants {
  id integer [primary key, increment]
  business_name varchar(200) [not null]
  trade_license_no varchar(100) [unique, not null]
  user_id integer [unique, not null]
  tier varchar(20) [not null, default: 'BRONZE', note: 'BRONZE (0%) | SILVER (3%) | GOLD (7%) | PLATINUM (10%)']
  total_spent_last_3_months decimal(12,2) [not null, default: 0.00]
  credit_limit decimal(12,2) [not null, default: 5000.00]
  created_at timestamp [not null]
  updated_at timestamp [not null]

  indexes {
    business_name
    tier
  }
}

// ─── 4. Cold-Chain Inventory & FEFO Batches ──────────────────────────────────

Table perishable_items {
  id integer [primary key, increment]
  name varchar(200) [not null]
  category varchar(30) [not null, default: 'PRODUCE', note: 'DAIRY | MEAT_POULTRY | SEAFOOD | PRODUCE | FROZEN | BEVERAGES']
  required_temp_celsius decimal(5,2) [not null, note: 'Target storage temperature in Celsius']
  temp_tolerance_celsius decimal(4,2) [not null, default: 1.00, note: 'Allowed drift +/- C']
  standard_shelf_life_days integer [not null, note: 'Expected shelf-life under cold-chain']
  unit_of_measure varchar(20) [not null, default: 'kg', note: 'kg, liter, crate, unit']
  created_at timestamp [not null]

  indexes {
    name
    category
  }
}

Table stock_batches {
  id integer [primary key, increment]
  batch_number varchar(64) [unique, not null, note: 'Unique tracking batch code, e.g. CB-402']
  item_id integer [not null]
  harvest_pack_date date [not null]
  expiry_date date [not null, note: 'Key sort key for algorithmic FEFO stock allocation']
  initial_quantity decimal(12,2) [not null]
  current_quantity decimal(12,2) [not null]
  purchase_cost decimal(10,2) [not null]
  base_selling_price decimal(10,2) [not null]
  status varchar(20) [not null, default: 'AVAILABLE', note: 'AVAILABLE | FLASH_SALE (30% markdown) | EXPIRED | DEPLETED']
  storage_bin varchar(50) [not null, default: 'COLD-ZONE-A1']
  created_at timestamp [not null]
  updated_at timestamp [not null]

  indexes {
    expiry_date
    status
    (item_id, status, expiry_date)
  }
}

// ─── 5. B2B Orders & FEFO Allocation ─────────────────────────────────────────

Table orders {
  id integer [primary key, increment]
  order_number varchar(32) [unique, not null, note: 'Generated tracking identifier, e.g. ORD-B2F04E71']
  restaurant_id integer [not null]
  status varchar(20) [not null, default: 'PENDING', note: 'PENDING | ALLOCATED | DISPATCHED | DELIVERED | CANCELLED']
  subtotal_amount decimal(12,2) [not null, default: 0.00]
  tier_discount_percent decimal(5,2) [not null, default: 0.00]
  discount_amount decimal(12,2) [not null, default: 0.00]
  total_amount decimal(12,2) [not null, default: 0.00]
  created_at timestamp [not null]
  updated_at timestamp [not null]

  indexes {
    status
    created_at
  }
}

Table order_items {
  id integer [primary key, increment]
  order_id integer [not null]
  item_id integer [not null]
  batch_id integer [note: 'Assigned stock batch via atomic FEFO select_for_update()']
  quantity_ordered decimal(12,2) [not null]
  unit_price decimal(10,2) [not null]
  subtotal decimal(12,2) [not null]
}

// ─── 6. Wastage & Scrap Logging ──────────────────────────────────────────────

Table wastage_logs {
  id integer [primary key, increment]
  batch_id integer [not null]
  quantity_lost decimal(12,2) [not null]
  financial_loss decimal(12,2) [not null]
  reason varchar(30) [not null, default: 'EXPIRED', note: 'EXPIRED | COLD_CHAIN_BREACH | PHYSICAL_DAMAGE | QUALITY_REJECT']
  logged_by_id integer
  created_at timestamp [not null]

  indexes {
    reason
    created_at
  }
}

// ─── Foreign Key Relationships (Refs) ────────────────────────────────────────

// User & Profiles
Ref: restaurants.user_id - users.id // one-to-one
Ref: employee_profiles.user_id - users.id // one-to-one
Ref: employee_profiles.department_id > departments.id // many-to-one
Ref: employee_profiles.reporting_manager_id > employee_profiles.id // self-referential
Ref: employee_profiles.created_by_id > users.id

// Employee Audit & History
Ref: employment_histories.employee_id > employee_profiles.id
Ref: employment_histories.changed_by_id > users.id
Ref: audit_logs.actor_id > users.id
Ref: audit_logs.target_user_id > users.id

// Inventory & Batches
Ref: stock_batches.item_id > perishable_items.id // many-to-one

// Orders & Order Items
Ref: orders.restaurant_id > restaurants.id // many-to-one
Ref: order_items.order_id > orders.id // many-to-one
Ref: order_items.item_id > perishable_items.id // many-to-one
Ref: order_items.batch_id > stock_batches.id // many-to-one (optional before allocation)

// Wastage Logs
Ref: wastage_logs.batch_id > stock_batches.id // many-to-one
Ref: wastage_logs.logged_by_id > users.id // many-to-one

// ─── Actual Seeded System Records ────────────────────────────────────────────

Records users(id, username, role, phone_number) {
  1, 'ahmed_rahman', 'ADMIN', '+880 1711 000111'
  2, 'warehouse_demo', 'WAREHOUSE_MANAGER', '+880 1712 345678'
  3, 'admin_demo', 'ADMIN', '+880 1700 123456'
  4, 'sales_demo', 'SALES_AGENT', '+880 1713 998877'
  5, 'bistro_chef', 'RESTAURANT_CLIENT', '+880 1819 001122'
}

Records departments(id, name, code, is_active) {
  1, 'Warehouse & Logistics', 'WH-LOG', true
  2, 'Operations', 'OPS', true
  3, 'Sales & Client Relations', 'SALES', true
  4, 'Executive & Administration', 'EXEC', true
}

Records employee_profiles(id, user_id, employee_id, official_full_name, designation, department_id, work_location) {
  1, 1, 'FF-OPS-0002', 'Ahmed Rahman', 'Operations Director', 2, 'Dhaka Warehouse (Main)'
  2, 2, 'FF-WH-0024', 'Mohammad Ahsan', 'Warehouse Manager', 1, 'Dhaka Warehouse (Main)'
  3, 3, 'FF-AD-0001', 'Tanvir Ahmed', 'System Administrator', 4, 'Corporate HQ (Dhaka)'
  4, 4, 'FF-SA-0010', 'Samira Khan', 'Sales Representative', 3, 'Dhaka Warehouse (Main)'
}

Records restaurants(id, business_name, trade_license_no, user_id, tier, total_spent_last_3_months, credit_limit) {
  1, 'The French Bistro', 'TL-DHK-2024-8841', 5, 'GOLD', 18500.00, 10000.00
}

Records perishable_items(id, name, category, required_temp_celsius, standard_shelf_life_days, unit_of_measure) {
  1, 'Norwegian Salmon Fillet', 'SEAFOOD', -2.00, 10, 'kg'
  2, 'Prime Ribeye Steak', 'MEAT_POULTRY', 1.50, 14, 'kg'
  3, 'Organic Chicken Breast', 'MEAT_POULTRY', 1.00, 7, 'kg'
  4, 'Fresh Mozzarella', 'DAIRY', 3.00, 21, 'unit'
  5, 'Romaine Lettuce Hearts', 'PRODUCE', 4.00, 12, 'crate'
}

Records stock_batches(id, batch_number, item_id, expiry_date, current_quantity, base_selling_price, status, storage_bin) {
  1, 'CB-402', 1, '2026-11-25', 120.00, 26.00, 'AVAILABLE', 'COLD-ZONE-B2'
  2, 'CB-403', 2, '2026-11-28', 175.00, 34.50, 'AVAILABLE', 'COLD-ZONE-A1'
  3, 'CB-404', 3, '2026-11-21', 90.00, 10.00, 'FLASH_SALE', 'COLD-ZONE-A2'
  4, 'CB-405', 4, '2026-12-05', 85.00, 12.50, 'AVAILABLE', 'COLD-ZONE-C1'
  5, 'CB-406', 5, '2026-11-29', 65.00, 18.00, 'AVAILABLE', 'COLD-ZONE-D1'
}

Records orders(id, order_number, restaurant_id, status, subtotal_amount, discount_amount, total_amount) {
  1, 'ORD-B2F04E71', 1, 'ALLOCATED', 1200.00, 84.00, 1116.00
}

Records order_items(id, order_id, item_id, batch_id, quantity_ordered, unit_price, subtotal) {
  1, 1, 1, 1, 25.00, 26.00, 650.00
  2, 1, 3, 3, 55.00, 10.00, 550.00
}

Records wastage_logs(id, batch_id, quantity_lost, financial_loss, reason, logged_by_id) {
  1, 3, 10.00, 85.00, 'EXPIRED', 2
}
