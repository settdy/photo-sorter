# Photo Sorter for Windows

A simple Windows program that organises photos using their **Creation Time**.

## What It Does

The program will: 
- Creates year and month folders
- Moves your images into the respective folders
- Deletes empty folders left behind after moving photos

The program won't:
- Overwrite files when duplicate file occurs
- Change the metadata of images 

## Options:
Rename / Keep original 
- Rename your images in a "YYYYMMDD_XXX" format, where XXX are the numbers
- Keep original image name (In cases of duplicate file names, a number will be added after the name)
- Rename your images in "YYYYMMDD_NAME" format

Move or Copy
- Move your original images
- Copy your images and move them

Example result:

```text
Selected Folder/
├── 2025/
│   ├── 2025-11/
│   └── 2025-12/
└── 2026/
    ├── 2026-01/
    └── 2026-02/
   
   Example Image Name: 20261225_001