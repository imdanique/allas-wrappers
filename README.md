# allas-wrappers

Convenience wrappers around [allas-cli-utils](https://github.com/CSCfi/allas-cli-utils) for downloading and uploading data to CSC Allas object storage, developed for use at FIMM.

---

## Rationale

`allas-cli-utils` provides the core tools for working with Allas, but downloading multiple files in practice involves several steps: listing bucket contents, looping through files, re-authenticating every 8 hours, and decrypting crypt4gh-encrypted files. `allas-wrappers` wraps these steps into a single command.

## Requirements

- [allas-cli-utils](https://github.com/CSCfi/allas-cli-utils) installed and configured
- [sd-lock-util](https://github.com/CSCfi/sd-lock-util) (only required for SD Connect encrypted data)
- A CSC account with access to the relevant Allas project
- A crypt4gh keypair

---

## Scripts

### `allas_get.sh`

Downloads and decrypts files from an Allas container. Handles automatic token refresh before each file to avoid mid-download authentication failures on long-running jobs.

**Usage:**

```bash
./allas_get.sh <container_path>
```

**Example:**

```bash
./allas_get.sh PARENT_DIR/CHILD_DIR
```

The script will prompt for:
- CSC password
- crypt4gh key passphrase
- Allas project name (e.g. `project_0000000`)

**What it does:**

1. Authenticates to Allas using `allas_conf`
2. Lists all `.c4gh` files in the container using `a-list`
3. For each file:
   - Refreshes the Allas token (non-interactively, since `OS_PASSWORD` is kept in memory)
   - Downloads and decrypts using `a-get --sk`
   - Strips the container prefix from the output path to avoid redundant directory nesting
4. Reports any failed files at the end and exits with a non-zero status if any failures occurred

**Configuration:**

Edit the variables at the top of the script before use:

```bash
ALLAS_CLI_UTILS="/path/to/allas-cli-utils/"
OS_USERNAME="your-csc-username"
C4GH_KEY="$HOME/.c4gh/your.sec"
```

---

## Notes

- Token refresh calls `allas_conf` before every file. This is intentional — it ensures the token is always valid at the start of a download regardless of how long the previous file took. The call is non-interactive as long as `OS_PASSWORD` is exported.
- The container prefix is stripped from output paths. For example, a file stored as `PARENT_DIR/CHILD_DIR/DIR/sample.fastq.gz.c4gh` will be written to `./DIR/sample.fastq.gz`.

---

## TODO

- [ ] Add support for SD Connect (`--sdc`) encrypted downloads
- [ ] Add `allas_put.sh` for uploads (plain, crypt4gh, and SD Connect modes)
- [ ] Unify into a single `allas-get` / `allas-put` interface with `--mode` flag
- [ ] Add `--dry-run` option to list files without downloading
- [ ] Add resume support — skip files that already exist locally
- [ ] Add checksum verification post-download

---

## Related

- [allas-cli-utils](https://github.com/CSCfi/allas-cli-utils) — CSC's official Allas command-line tools
- [sd-lock-util](https://github.com/CSCfi/sd-lock-util) — SD Connect encryption/decryption utility
- [CSC Allas documentation](https://docs.csc.fi/data/Allas/)

