-- Lets the admin dashboard record an optional reason when rejecting a
-- location's approval request.
-- Run this manually against your Supabase project's SQL editor.

alter table locations add column if not exists rejection_reason text;

-- Approval state is derived from existing columns (no separate status enum):
--   pending  -> documents_verified = false AND rejection_reason IS NULL
--   approved -> documents_verified = true
--   rejected -> documents_verified = false AND rejection_reason IS NOT NULL
