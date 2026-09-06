# Photo Sorter for Windows

A simple Windows program that organises photos using their **Date Taken**.

## What It Does

The program:

- Moves photos by default
- Sorts them into year and month folders
- Renames them in date order
- Preserves embedded photo metadata
- Preserves the original Windows creation time
- Deletes empty folders left behind after moving photos
- Does not overwrite existing photos

Example result:

```text
Selected Folder/
├── 2025/
│   ├── 2025-11/
│   └── 2025-12/
└── 2026/
    ├── 2026-01/
    └── 2026-02/
