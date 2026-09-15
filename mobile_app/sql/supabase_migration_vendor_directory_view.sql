CREATE VIEW vendor_directory AS
SELECT vendor_application_id, business_name, contact_number, stall_number, stall_location,
       stall_house_number, stall_street, stall_barangay, stall_city, stall_province,
       stall_postal_code, stall_country, stall_lat, stall_lng,
       store_description, store_hours, store_categories
FROM vendor_applications
WHERE status = 'approved';

GRANT SELECT ON vendor_directory TO authenticated, anon;
