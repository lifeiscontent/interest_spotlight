# InterestSpotlight

## Setup

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Create the uploads directories:
   ```bash
   mkdir -p /path/to/your/uploads
   mkdir -p /path/to/your/test/uploads
   ```

   For example:
   ```bash
   mkdir -p /home/johndoe/Documents/partitions/interest_spotlight
   mkdir -p /home/johndoe/Documents/partitions/interest_spotlight/tests
   ```

3. Edit `.env` and set the paths to your created directories:
   ```bash
   export UPLOADS_DIRECTORY="/path/to/your/uploads"
   export UPLOADS_DIRECTORY_TEST="/path/to/your/test/uploads"
   ```

   For example:
   ```bash
   export UPLOADS_DIRECTORY="/home/johndoe/Documents/partitions/interest_spotlight"
   export UPLOADS_DIRECTORY_TEST="/home/johndoe/Documents/partitions/interest_spotlight/tests"
   ```

4. Load environment variables:
   ```bash
   source .env
   ```

5. Install dependencies and setup the database:
   ```bash
   mix setup
   ```

6. Start the Phoenix server:
   ```bash
   mix phx.server
   ```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `UPLOADS_DIRECTORY` | Directory for storing user uploads (profile photos). Must exist and be writable. | Yes (dev/prod) |
| `UPLOADS_DIRECTORY_TEST` | Directory for storing test uploads. Must exist and be writable. | Yes (test) |

## Running Tests

```bash
source .env
mix test
```

## Production

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
