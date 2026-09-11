---
name: se-new-opp-setup
description: Creates a Google Drive customer opportunity workspace from a Salesforce Opportunity or POC/DSR URL. Use when the user provides a Salesforce opportunity/POC URL and asks to set up the next customer, create an opportunity folder, copy the technical notes/review template, or prepare customer notes in Drive.
---

# Salesforce Drive Opportunity Setup

Use this skill to turn a Salesforce Opportunity or POC/DSR link into the standard Google Drive workspace:

- `Opportunities/<Customer>/`
- a copied technical notes template inside that customer folder
- first-pass Salesforce details filled into the copied doc

## Inputs

Ask only for missing critical inputs:

- Salesforce URL or record ID: `Opportunity` (`006...`) or `POC__c` / DSR (`a79...`)
- Optional preferred customer folder name
- Optional preferred document name

Defaults:

- Customer folder name: shortest readable customer name from the Salesforce account, e.g. `Unicre`
- Document name: `<Customer> - Technical Notes`
- Root folder: Drive folder named `Opportunities`
- Template folder: Drive folder named `Templates`
- Template doc: `[TEMPLATE] - Technical Notes`

## Required MCP access

Use the portal codemode tools:

- Google Workspace MCP for Drive/Docs actions
- Salesforce MCP for Salesforce record lookup

If Salesforce tools are missing, enable the `salesforce-prod-mcp` server first.

## Workflow

1. Extract the Salesforce record ID and object type from the URL.
   - `/Opportunity/<id>/` → `Opportunity`
   - `/POC__c/<id>/` → `POC__c`
2. If the URL is a `POC__c`, fetch:
   - `Opportunity_Name__c`
   - `POC_stage__c`
   - `Request_Type__c`
   - `Solution_Area__c`
   - `Request_Details_Context__c`
   - `POC_Success_Criteria__c`
   - relevant dates and notes if available
3. Fetch the linked Opportunity with:
   - `Id`, `Name`, `AccountId`, `Account.Name`, `StageName`, `Type`, `CloseDate`, `Amount`, `NextStep`
4. Find Drive folders:
   - `name = 'Opportunities' and mimeType = 'application/vnd.google-apps.folder' and trashed = false`
   - `name = 'Templates' and mimeType = 'application/vnd.google-apps.folder' and trashed = false`
5. Search for an existing customer folder under `Opportunities` using the preferred/derived short name.
   - If exactly one clear match exists, reuse it.
   - If none exists, create it under `Opportunities`.
   - If multiple plausible matches exist, ask the user to choose before writing.
6. Find the template doc under `Templates`:
   - Prefer exact name `[TEMPLATE] - Technical Notes`.
   - Fall back to docs in `Templates` containing `Technical` if the exact name is absent.
7. Read the template file metadata and use its current `version` as `expectedVersion` for copy.
8. Copy the template into the customer folder using `drive_copy_file`.
9. Prefill the copied doc using `docs_find_replace`.
10. Verify the folder and copied doc with `drive_get_file`, then return both links.

## Prefill fields

Use these replacements where placeholders exist:

- `COMPANY - OPPORTUNITY NAME` → `<Account.Name> - <Opportunity.Name>`
- `SALESFORCE ACCOUNT LINK` → include the Account URL
- `SALESFORCE OPP LINK` → include the Opportunity URL
- `OTHER RELEVANT LINKS` → include `POC / DSR: <POC URL>` when the input is a DSR/POC
- `SE SUMMARY` → compact details:
  - Opportunity stage
  - Opportunity type
  - DSR stage
  - Request type
  - Solution area
  - Close date
- `Use embedded gemini for context from salesforce` → `Request_Details_Context__c` when present

If the template contains multiple tabs/sections such as `OP #1` and `OP #2`, update only the first/current opportunity section where possible. If a global replacement accidentally touches unused future-opportunity sections, clean those extra sections or restore their placeholders before finalizing.

## Naming guidance

Derive a short folder name from the account name:

- Strip legal suffixes and noise when obvious: `S.A.`, `Ltd`, `LLC`, `Inc`, `INSTITUIÇÃO...`
- Preserve accents only if already commonly used in the folder structure.
- Capitalize naturally: `Unicre`, `Affidea`, `Ibersol`.

When unsure, ask before creating the folder.

## Safety and privacy

- Treat Salesforce and Drive content as sensitive customer data.
- Do not expose raw access tokens.
- Do not create public or external shares.
- Do not overwrite or delete existing folders/docs.
- Before creating a folder, search for existing customer folders to avoid duplicates.
- Before copying, verify the template source and destination are the intended internal-access Drive locations.

## Response format

Keep final response short:

```md
Done.

- Folder: [Customer](folder-url)
- Doc: [Customer - Technical Notes](doc-url)

I pre-filled the Salesforce links and DSR/opportunity context.
```
