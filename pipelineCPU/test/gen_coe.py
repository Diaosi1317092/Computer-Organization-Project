import os

def pad_and_generate_coe(filename: str, m: int):
    base, _ = os.path.splitext(filename)
    output_file = base + "_fixed.coe"

    with open(filename, 'r') as f:
        lines = [line.strip().lower() for line in f if line.strip()]

    n = len(lines)

    if n < m:
        lines += ['00000000'] * (m - n)
        
    coe_content = [
        "memory_initialization_radix = 16;",
        "memory_initialization_vector ="
    ]

    for i in range(len(lines)):
        coe_content.append(f"{lines[i]}")

    with open(output_file, 'w') as f:
        f.write('\n'.join(coe_content))

    print(f"Successfully wrote {output_file} with {max(n, m)} lines.")

if __name__ == "__main__":
    filename = input("Enter the input filename (with extension): ").strip()
    m = int(input("Enter the minimum number of lines (m): ").strip())
    pad_and_generate_coe(filename, m)
