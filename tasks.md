# Interest Spotlight - Tasks

## Completed

- [x] Add user_type field to users table (default: "user", admin: "admin")
- [x] Add first_name, last_name, location fields to users table
- [x] Create profiles table (bio, instagram, facebook, twitter, tiktok, youtube)
- [x] Create interests table with seed data (arts-focused interests)
- [x] Create user_interests join table
- [x] Update User schema with new fields and associations
- [x] Create Profile schema and Profiles context
- [x] Create Interest and UserInterest schemas and Interests context
- [x] Create onboarding check plug (require_onboarded) - checks first_name, last_name, location + 3 interests minimum
- [x] Create admin-only plug (require_admin)
- [x] Create user-only plug (require_user)
- [x] Create LiveView on_mount hooks for onboarding, admin, and user checks
- [x] Create onboarding LiveView flow:
  - [x] BasicInfo page (first_name, last_name, location)
  - [x] Interests selection page (minimum 3 interests)
  - [x] About page (bio, social profiles - optional)
- [x] Update router with:
  - [x] Onboarding routes (authenticated but no onboarding required)
  - [x] Regular user routes (authenticated + onboarded)
  - [x] Admin routes (/admin/*)
- [x] Create admin dashboard page
- [x] Create admin interests management page (add, edit, delete interests)
- [x] Run migrations
- [x] Fix session token query to load all user fields (first_name, last_name, location, user_type)
- [x] Update existing tests to include onboarding data in user fixtures
  - [x] Added `onboarded_user_fixture()` - creates user with profile info + 3 interests
  - [x] Added `admin_fixture()` - creates admin user
  - [x] Added `register_and_log_in_onboarded_user` setup helper
  - [x] Added `register_and_log_in_admin` setup helper
  - [x] Updated profile_live_test.exs
  - [x] Updated settings_test.exs
  - [x] Updated user_session_controller_test.exs

## Pending

- [ ] Add tests for onboarding flow
- [ ] Add tests for admin pages
- [ ] Add tests for user type restrictions
- [ ] Create events system (events table, user can create events)
- [ ] Event discovery based on user interests
- [ ] User profile page (public view)
- [ ] Event RSVP functionality
