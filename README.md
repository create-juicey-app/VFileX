# VFileX - yet another VTF/VMT Editor

> A high-speed, cross-platform editor for Valve Material (.VMT) files.

Built with Rust + Qt (CXX-Qt/QML)

---

## Building from Source

### Prerequisites

- **Rust** (1.70 or later)
- **Qt 6** (6.4 or later)
- **CMake** (3.21 or later)
- **Ninja** (recommended)

#### Linux (Ubuntu/Debian)
```bash
sudo apt install qt6-base-dev qt6-declarative-dev cmake ninja-build
```

#### Linux (Fedora)
```bash
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel cmake ninja-build
```
#### Linux (Arch)
guess lol

#### Windows
1. Install [Qt 6](https://www.qt.io/download) with MSVC components
2. Install [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/)
3. Install [CMake](https://cmake.org/download/)

#### macOS
```bash
brew install qt@6 cmake ninja
```

### Build

```bash
# Clone the repository
git clone https://github.com/create-juicey-app/VFileX.git
cd VFileX

# Build with release optimizations
cargo build --release

# Run
cargo run --release
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- **Valve Software & gabe** for the VTF/VMT formats
- **CXX-Qt** team for the Rust-Qt bindings
- **keyvalues-parser** crate authors
