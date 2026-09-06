# Hardware & Environment Specifications (as of Sept 6, 2026)

## Paul's Workstation Laptop

### Machine Profile & Context Injection (AI-Optimized YAML)

```yaml
system_profile:
  device_name: "ASUS ROG Zephyrus G15 (GA503RM)"
  form_factor: "Gaming / Creator Laptop"
  operating_system:
    os: "Microsoft Windows 11 Home"
    architecture: "x64 (64-bit)"
    kernel_build: "10.0.26200"
    primary_shell: "PowerShell"
  motherboard_and_bios:
    board_manufacturer: "ASUSTeK COMPUTER INC."
    board_product: "GA503RM v1.0"
    bios_version: "GA503RM.318 (American Megatrends)"
    bios_date: "2024-02-26"

processor_cpu:
  model: "AMD Ryzen 9 6900HS with Radeon Graphics"
  microarchitecture: "Zen 3+ (Rembrandt, 6nm TSMC)"
  cores_and_threads:
    physical_cores: 8
    logical_processors: 16
  clocks:
    base_clock: "3.30 GHz"
    max_boost_clock: "4.90 GHz"
  cache:
    l2_cache: "4 MB (4096 KB)"
    l3_cache: "16 MB (16384 KB)"
  tdp: "35W (HS high-efficiency series)"

system_memory_ram:
  total_installed: "16.0 GB (16,366,272,512 bytes)"
  usable_visible: "~15.24 GiB"
  technology: "DDR5"
  speed: "4800 MT/s (DDR5-4800)"
  channel_configuration: "Dual-Channel (1x Onboard + 1x SODIMM)"
  modules:
    - slot: "DIMM 0 (Onboard)"
      capacity: "8 GB"
      manufacturer: "Micron Technology"
      part_number: "MTC4C10163S1SC48BAY"
      speed: "4800 MHz"
    - slot: "DIMM 0 (Removable SODIMM)"
      capacity: "8 GB"
      manufacturer: "Samsung"
      part_number: "M425R1GB4BB0-CQKOL"
      speed: "4800 MHz"

dual_graphics_subsystem:
  dedicated_gpu_dgpu:
    role: "AI Acceleration / Compute / Heavy 3D"
    card_name: "NVIDIA GeForce RTX 3060 Laptop GPU"
    architecture: "NVIDIA Ampere (GA106, 8nm)"
    bus_id: "PCIe 0000:01:00.0"
    vram_dedicated: "6144 MiB (6.0 GB) GDDR6"
    compute_capability: "sm_86 (8.6)"
    cuda_version_supported: "CUDA 12.9"
    driver_version: "576.02 (WDDM 3.2)"
    tdp_power_limit: "Up to 107W (with Dynamic Boost)"
    hardware_compute_units:
      cuda_cores: 3840
      tensor_cores: 120 (3rd Generation)
      rt_cores: 30 (2nd Generation)
      video_engines: "NVENC (Gen 7) / NVDEC (Gen 5)"
    ai_guidance:
      - "Target device for CUDA, PyTorch (`cuda:0`), TensorRT, and ONNX Runtime CUDA provider."
      - "VRAM Ceiling: 6.0 GB max. Recommend 4-bit quantized LLMs (e.g. 7B/8B Q4_K_M GGUF, AWQ, or EXL2) or lightweight vision/embedding models."

  integrated_gpu_igpu:
    role: "Display Management / Video Decode / Power-Efficient Rendering"
    card_name: "AMD Radeon(TM) Graphics (Radeon 680M)"
    architecture: "AMD RDNA 2 (Rembrandt, 6nm)"
    compute_units: "12 CUs (768 Stream Processors)"
    vram_dedicated: "512 MB reserved + Shared Dynamic System RAM"
    driver_version: "31.0.12024.2005"
    display_mode: "2560 x 1440 (QHD) @ 32-bit color"
    hardware_decode: "AV1, VP9, HEVC/H.265, H.264"
    ai_guidance:
      - "Utilize for OS UI rendering and video decoding to keep dGPU VRAM 100% free for compute tasks."
      - "Supports DirectML and OpenCL if secondary acceleration is needed."

storage:
  primary_drive:
    model: "Western Digital PC SN735 NVMe SSD (SDBPNHH-512G-1002)"
    type: "NVMe PCIe M.2 SSD"
    physical_capacity: "512 GB"
  partitions:
    - drive_letter: "C:"
      file_system: "NTFS"
      total_space: "~453.5 GB"
      used_space: "~209.0 GB (~46%)"
      free_space: "~244.5 GB (~54%)"

networking:
  wifi: "MediaTek Wi-Fi 6E MT7922 (RZ616) 160MHz (2.4 Gbps Link Speed)"
  ethernet: "Realtek Gaming 2.5GbE Family Controller (2.5 Gbps)"
  bluetooth: "Bluetooth 5.2/5.3 (PAN)"
  vpn_mesh: "Tailscale Virtual Tunnel Active"

installed_runtimes_and_dev_tools:
  python: "3.13.14 (Path: C:\\Users\\pdo74\\AppData\\Local\\Programs\\Python\\Python313\\python.exe)"
  node_js: "v24.19.0 (Path: C:\\Program Files\\nodejs\\node.exe)"
  git: "v2.55.0.windows.3 (Path: C:\\Program Files\\Git\\cmd\\git.exe)"
  wsl: "Installed (WSL2 engine available via C:\\Windows\\system32\\wsl.exe)"
```

### Detailed Summary & AI Compute Directives

#### 1. Compute & Local AI Execution Boundaries
- **GPU Compute Selection (`cuda:0`):** Use the NVIDIA RTX 3060 Laptop GPU (6 GB GDDR6) for all PyTorch, TensorFlow, CUDA, TensorRT, and local inference engines (e.g., llama.cpp, vLLM, ExLlamaV2).
- **VRAM Budget Allocation:**
  - Usable VRAM: ~5.9 GB available when idle.
  - Recommended Model Sizes:
    - 7B–8B parameter models quantized to 4-bit (e.g., Q4_K_M, AWQ, GPTQ) fit comfortably with ~2k–4k context window.
    - 1B–3B parameter models fit in FP16/BF16.
    - Embeddings / Whisper / Small Vision models fit easily with room to spare.
- **CPU Fallback (`cpu`):** With 8 cores / 16 threads (Zen 3+ @ 4.9 GHz boost) and 16 GB DDR5-4800, CPU-based quantized inference (llama.cpp using AVX2) is viable for models exceeding the 6 GB VRAM threshold.

#### 2. Graphics Routing & Dual-GPU Behavior
- AMD Radeon 680M (iGPU) handles the internal laptop display (2560x1440 QHD) and desktop composition.
- NVIDIA RTX 3060 (dGPU) is connected via NVIDIA Optimus / Advanced Optimus switching. It enters low-power P0/P8 idle state with 0 MB baseline allocation until compute or 3D loads are dispatched.

#### 3. Environment & Storage
- OS: Windows 11 Home x64.
- Storage Headroom: ~244.5 GB free on the high-speed Western Digital NVMe SSD (C:\), sufficient for multiple local model checkpoints and dev caches.

---

## Paul's Single Home Server (Minisforum Mini PC)

### System Overview & Core Directives
Paul operates **only one home server**: a dedicated Linux mini PC (`minisforum`), reached privately via Tailscale at `gitserver.tail97bf76.ts.net`.

### Non-Negotiable Core Principles
1. **100% Private Network Boundary:** Accessible only via Tailscale private mesh (`*.tail97bf76.ts.net`). Never expose any ports to the LAN or public internet. Never propose cloud bridges or public tunnels.
2. **Single Ingress Architecture:** Tailscale provides a single HTTPS ingress on port 443 to a local Caddy reverse proxy on loopback (`http://127.0.0.1:8080`). Caddy manages internal routing.
3. **No Direct Port Exposure:** Applications bind exclusively to `127.0.0.1:<port>`. Port numbers are hidden plumbing—users never type ports.
4. **Single Source of Truth:** All routing declarations originate from `routes.json`. Drift between `routes.json`, `Caddyfile`, and `portal/index.html` fails closed.
5. **The Bare Address (`/`) is the Portal:** The root domain `https://gitserver.tail97bf76.ts.net/` is permanently owned by the static Home Portal. Applications are never mounted at `/`.

### Active Route Manifest & Service Inventory
Authoritative file: `/etc/server-router/routes.json` (canonical source: `repo-governance-templates/global/server-router/routes.json`).

| Mount Path | Type | Backend Target | Systemd Service | Path Prefix Handling | Description |
|---|---|---|---|---|---|
| `/` | `static` | `/var/www/portal` | `caddy.service` | N/A | Home Portal index linking all active apps |
| `/git` | `reverse_proxy` | `127.0.0.1:3000` | `forgejo.service` | Stripped (`uri strip_prefix /git`) | Forgejo Web UI & Git HTTP. `ROOT_URL` = `https://gitserver.tail97bf76.ts.net/git/` |
| `/mealprep` | `reverse_proxy` | `127.0.0.1:9100` | `mealprep.service` | Preserved | Meal Prep AI application |
| `/keycase` | `reverse_proxy` | `127.0.0.1:8787` | `keycase.service` | Preserved | Centralized API key management service |
| `/factory` | `reverse_proxy` | `127.0.0.1:3187` | `pauls-software-factory.service` | Preserved | Software factory dashboard & agent runner |
| `/neon-labrinth/` | `static` | `/var/www/neon-labrinth/dist` | `caddy.service` | Stripped for disk lookup | Static browser game assets |
| N/A | `ssh` | `127.0.0.1:22` | `ssh.service` / `sshd` | N/A | Host administration and Git SSH clone/push |

### 10 Server Operational Rules for AI Agents
1. **Bare address is the portal:** Never configure an application to serve directly on `/`.
2. **One word per app after the slash:** Use lowercase single-word naming matching repo name, folder name, and systemd service (e.g., `/mealprep`, `/keycase`, `/factory`).
3. **Hide plumbing:** Do not output raw URLs with port numbers (e.g., do not say `http://minisforum:9100`; say `https://gitserver.tail97bf76.ts.net/mealprep`).
4. **Never run `tailscale serve <target> off`:** In this Tailscale version, running `off` on a specific target wipes the entire node routing table and takes down all services. Rebuild routes using canonical router scripts.
5. **`routes.json` is the sole source of truth:** Do not manually edit `/etc/caddy/Caddyfile` directly on the server without reflecting changes in `routes.json`, the local Caddyfile, and `portal/index.html`.
6. **Use canonical tooling:** Execute deployments and verifications through `Deploy-ServerRouter.ps1` and `Verify-ServerRouter.ps1` (or desktop wrapper `Fix-Server-Addresses.ps1`).
7. **Forgejo prefix behavior:** Forgejo expects root-relative requests internally (`/`), but its public `ROOT_URL` in `/etc/forgejo/app.ini` must remain `https://gitserver.tail97bf76.ts.net/git/`.
8. **Subpath mounting compliance:** Web apps must support running under a prefix (e.g., using `unmount()` in Python WSGI/ASGI or dynamic `APPBASE` paths in frontend JavaScript).
9. **Atomic changes:** Adding or removing an application requires updating all 3 artifacts together (`routes.json`, `Caddyfile`, `portal/index.html`).
10. **Loopback binding:** All backend services must listen strictly on `127.0.0.1`, not `0.0.0.0`. Caddy blocks LAN access on port 8080.
