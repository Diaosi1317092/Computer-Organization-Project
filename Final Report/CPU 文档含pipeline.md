# CPU 文档

## 小组成员

|   学号   |  姓名  |  实验课时间  |
| :------: | :----: | :----------: |
| 12312420 | 王振宇 | 周三 7 ~ 8节 |
| 12312505 | 江博成 | 周三 7 ~ 8节 |
| 12311153 | 廖子韬 | 周三 7 ~ 8节 |

## 1. 开发计划日程安排和实施情况

|    日程     |                      安排                      | 实施情况 |
| :---------: | :--------------------------------------------: | :------: |
|  5.1 ~ 5.2  |            单周期 CPU + 扩展指令集             |   完成   |
| 5.14 ~ 5.18 | Pipeline CPU + Uart 外设（键盘输入和前端显示） |   完成   |
| 5.19 ~ 5.21 |       Debug 模式（集成机器码反编译工具）       |   完成   |
| 5.22 ~ 5.25 |        Uart 切换测试场景 + 固定时钟周期        |   完成   |

## 2. CPU特性说明

- **CPU结构：**分别实现单周期 CPU 和 Pipelined CPU

- **单周期时钟周期：**25 MHz (CPU);  10 MHz (UART 切换测试场景)

- **Pipeline时钟周期：** 50 MHz (超频后 75 MHz);

- **单周期 CPI：**CPI ≈ 1

- **Pipeline CPI：**CPI ≈ 1

- **寻址空间设计：**哈佛结构

- **IO方式：**利用 `ecall` 进行输入输出

- **支持的指令集：**RISC-V32
  已实现 Blackboard 提供的 RISC-V32 Reference Card 第一页的全部指令（不包含 `ebreak`；`ecall`支持 `1`,`5`,`34`,`35`）

  | 类型               | 指令                                           |
  | ------------------ | ---------------------------------------------- |
  | `R-type (0110011)` | `add,sub,xor,or,and,sll,srl,sra,slt,sltu`      |
  | `I-type (0010011)` | `addi,xori,ori,andi,slli,srli,srai,slti,sltiu` |
  | `I-type (0000011)` | `lb,lh,lw,lbu,lhu`                             |
  | `I-type (1100111)` | `jalr`                                         |
  | `I-type (1110011)` | `ecall(1,5,34,35)`                             |
  | `S-type (0100011)` | `sw,sh,sb`                                     |
  | `B-type (1100011)` | `beq,bne,blt,bge,bltu,bgeu`                    |
  | `U-type (0110111)` | `lui`                                          |
  | `U-type (0010111)` | `auipc // single cycle CPU`                    |
  | `J-type (1101111)` | `jal`                                          |

#### 单周期 CPU 顶层模块结构：

* `TopModule`
  * `ClockDivder`
  * `IFetch`
  * `Decoder`
  * `ALU`
  * `Controller`
  * `DMem`
  * `WriteBackMUX`
  * `InputModule`
  * `OutputModule`
    * `SegGnerator`
    * `SegDisplay`
  * `UartTop`
    * `UartTx`
    * `UartRx`
    * `UartReg`

#### 单周期 CPU 顶层模块内包含以下信号线

| 类型及位宽    | 名称                   | 输出的模块     | 输入的模块                                             |
| ------------- | ---------------------- | -------------- | ------------------------------------------------------ |
| `wire`        | `clk`                  | `ClockDivider` | `IFetch`/`Decoder`/`DMem`/`InputModule`/`OutputModule` |
| `wire`        | `clk_de`               | `ClockDivider` | `InputModule`                                          |
| `wire`        | `done_input`           | `InputModule`  | `WriteBackMUX`/`Controller`                            |
| `wire [31:0]` | `input_data`           | `InputModule`  | `WriteBackMUX`                                         |
| `wire [31:0]` | `inst`                 | `IFetch`       | `Decoder`/`Controller`                                 |
| `wire [31:0]` | `pc`                   | `IFetch`       | `ALU`/`WriteBackMUX`                                   |
| `wire [31:0]` | `imm32`                | `Decoder`      | `IFetch`/`ALU`                                         |
| `wire [31:0]` | `rs1_data`             | `Decoder`      | `ALU`                                                  |
| `wire [31:0]` | `rs2_data`             | `Decoder`      | `ALU`/`DMem`                                           |
| `wire [31:0]` | `reg_a7`               | `Decoder`      | `Controller`/`OutputModule`                            |
| `wire [31:0]` | `output_data`          | `Decoder`      | `OutputModule`                                         |
| `wire`        | `zero`                 | `ALU`          | `IFetch`                                               |
| `wire [31:0]` | `alu_result`           | `ALU`          | `IFetch`/`DMem`/`WriteBackMUX`                         |
| `wire`        | `alu_src`              | `Controller`   | `ALU`                                                  |
| `wire [1:0]`  | `alu_op`               | `Controller`   | `ALU`                                                  |
| `wire`        | `branch`               | `Controller`   | `IFetch`                                               |
| `wire`        | `mem_read`             | `Controller`   | `DMem`                                                 |
| `wire`        | `mem_write`            | `Controller`   | `DMem`                                                 |
| `wire`        | `mem_to_reg`           | `Controller`   | `WriteBackMUX`                                         |
| `wire`        | `reg_write`            | `Controller`   | `Decoder`                                              |
| `wire`        | `is_jal`               | `Controller`   | `IFetch`/`WriteBackMUX`                                |
| `wire`        | `is_jalr`              | `Controller`   | `IFetch`/`WriteBackMUX`                                |
| `wire`        | `is_lui`               | `Controller`   | `ALU`                                                  |
| `wire`        | `is_auipc`             | `Controller`   | `ALU`                                                  |
| `wire`        | `en_pc`                | `Controller`   | `IFetch`/`Decoder`/`DMem`                              |
| `wire`        | `en_input`             | `Controller`   | `Decoder`/`WriteBackMUX`                               |
| `wire`        | `en_output`            | `Controller`   | `Decoder`/`OutputModule`                               |
| `wire [31:0]` | `mem_read_data`        | `DMem`         | `WriteBackMUX`                                         |
| `wire [31:0]` | `reg_write_data`       | `WriteBackMUX` | `Decoder`                                              |
| `wire [2:0]`  | `funct3 = inst[14:12]` | /              | `ALU`/`DMem`/`WriteBackMUX`                            |
| `wire [6:0]`  | `funct7 = inst[31:25]` | /              | `ALU`                                                  |

## 3. 方案分析说明

TODO

## 4. 系统上板使用说明

本项目使用了 EGO1 开发板

![演示图](E:\U\Assignment\CS202\Project\最终答辩\演示图.jpg)

- **复位设置：**通过板载 `RESET` 按钮实现复位，控制各模块的初始化。
- **板上输入设备：**通过 `P5,P4,P3,P2,R2,M4,N4,R1` 八个拨码开关实现一个 8-bit 二进制数的输入。
- **板上输出设备：**通过 `F6,G4,G3,J4,H4,J3,J2,K2` 八个 LED 进行二进制输出，通过八段数码管进行十进制（有符号）和十六进制的输出。输出类型由具体 `ecall` 指令决定。
- **确认类按键：**`V1` 按键用于确认启动 Communicate 模式，`R15` 按键用于确认当前拨码开关的输入，`R11` 按键用于确认用 UART 前端发送的数据作为输入。
- **模式切换：**`U3` 开关用于切换八段数码管显示（常规输出/性能测试输出），`R3` 开关用于切换 UART 接口（前端显示/测试场景切换），`T5` 开关用于进入 Debug 模式（仅在 Pipeline 模式中可用）。

## 5. 自测试说明

| 模块（单周期 CPU） | 测试方法  | 测试类型 | 测试用例                                                     | 测试结果 |
| ------------------ | --------- | -------- | ------------------------------------------------------------ | -------- |
| `top_module`       | 仿真/上板 | 集成     | 通过 BaseTest1.asm, BaseTest2.asm, FibTest.asm 进行集成测试。 | 通过     |
| `ClockDivider`     | 仿真      | 单元     | `tb_ClockDivider` 模拟各个信号变化，通过 `fatal` 输出异常。  | 通过     |
| `Controller`       | 仿真      | 单元     | `tb_Controller` 模拟各个信号变化，通过 `fatal` 输出异常。    | 通过     |
| `Dmem`             | 仿真      | 单元     | `tb_Dmem` 模拟各个信号变化，通过 `fatal` 输出异常。          | 通过     |
| `Decoder`          | 仿真      | 单元     | `tb_Decoder` 模拟各个信号变化，通过 `fatal` 输出异常。       | 通过     |
| `IFetch`           | 仿真      | 单元     | `tb_IFetch` 模拟各个信号变化，通过 `fatal` 输出异常。        | 通过     |
| `InputModule`      | 仿真      | 单元     | `tb_InputModule` 模拟各个信号变化，通过 `fatal` 输出异常。   | 通过     |
| `OutputModule`     | 上板      | 单元     | 新建项目 Demo，上板观察八段数码管输出。                      | 通过     |
| `SegDisplay`       | 仿真      | 单元     | `tb_SegDisplay` 模拟各个信号变化，通过 `fatal` 输出异常。    | 通过     |
| `SegGenerator`     | 仿真      | 单元     | `tb_SegGenerator` 模拟各个信号变化，通过 `fatal` 输出异常。  | 通过     |
| `WriteBackMUX`     | 仿真      | 单元     | `tb_WriteBackMUX` 模拟各个信号变化，通过 `fatal` 输出异常。  | 通过     |

| 模块（Uart 前端） | 测试方法 | 测试类型 | 测试用例 | 测试结果 |
| ----------------- | -------- | -------- | -------- | -------- |
| `UartTop`         | 上板     | 集成     | /        | 通过     |
| `UartRx`          | 上板     | 集成     | /        | 通过     |
| `UartTx`          | 上板     | 集成     | /        | 通过     |
| `UartReg`         | 上板     | 集成     | /        | 通过     |

## 6. 开源及 AI 对于本次大作业的启发和帮助

在本次 CPU 设计与调试项目中，我们借助了开源资料和人工智能工具，显著提升了开发效率和系统稳定性，主要体现在以下几个方面：

### 利用 AI 生成测试样例程序

在验证阶段，我们使用 AI 工具（如 ChatGPT）辅助编写了多个基础测试程序，如 `BaseTest1.asm` 和 `BaseTest2.asm`，其内容覆盖基本的算术、跳转、访存等指令操作。这大大减少了人工手写测试样例的负担，并提升了对边界条件和边缘指令行为的测试覆盖度。

### 利用 AI 生成Verilog 仿真测试

除指令测试外，我们还通过 AI 自动生成了 Verilog 单元模块的测试平台（testbench），例如针对 Controller、ALU、DMem 等模块的输入激励和断言检查逻辑。AI 工具能根据模块输入输出自动生成标准化、可复用的仿真模板，帮助我们更快地发现潜在 bug，并验证模块接口一致性。

### 开源设计优化 UART 通信模块（Bonus）

我们参考了知乎专栏文章《FPGA协议篇：最简单且通用verilog实现UART协议》（[链接](https://zhuanlan.zhihu.com/p/687628445)）中的设计思路与状态机逻辑，构建了可靠的 `UartRx` 和 `UartTx` 模块。该文章提供了详实的位时序控制方法与模块划分方案，帮助我们构建了稳定的串口收发基础框架，并在此基础上扩展出 `UartReg` 及 `uart32_8` 等模块（自设计），实现批量字节流数据输出。

### 借助 AI 快速开发图形前端调试工具（Bonus）

我们本次项目的一个重要创新是通过自研 GUI 工具对 CPU 状态进行可视化调试，包括显示寄存器值、PC 值、流水线阶段、机器码反编译结果等。该 GUI 使用 Python 编写，并通过 `tkinter` 库实现界面组件。

## 7. 问题及总结

### Pipeline 实现复杂（Bonus）

本次项目采用五级流水线架构（IF、ID、EXE、MEM、WB），虽然理论上能够提高执行效率，但在实际设计中带来了较大的实现复杂度。各阶段之间的数据通路需要精确控制，稍有不慎就会引入错误。同时，流水线 Data Hazard 和 Control Hazard 的处理是调试中的重点和难点。在设计中我们采用了暂停机制以及跳转指令快速判断策略，但这些策略的正确性需要大量的测试与验证。为了提升调试效率，我们设计了流水线阶段的机器码输出功能，并通过串口发送到上位机进行可视化，从而辅助我们追踪指令执行流程。

**思考：**复杂结构必须分阶段验证。

### UART 传输速率受限（Bonus）

由于 UART 接口采用逐字节串行发送，数据吞吐量有限，导致一次完整传输寄存器和流水线信息需要较长时间。为了适应这一特点，我们在设计中引入了基于状态机的分批发送机制，使得每条指令完成后以较小延迟将相关信息完整送出。同时在上位机端采用异步解码方式进行实时还原和显示，从而在带宽受限的情况下实现了较为流畅的状态观察体验。

**思考：**未来设计中可考虑 PS/2 或自定义 AXI-lite 接口以替代传统 UART，提高吞吐效率。

### 软硬件协同困难（Bonus）

软硬件协同设计的本质在于信息从硬件流向软件、再反馈至调试界面，这一过程若无良好接口，往往难以同步。我们在 Verilog 代码中添加了多个状态输出端口，并由自定义模块 `UartReg` 控制每条数据的发送时序，确保每次数据更新都有序输出。

**思考：**用状态驱动的方式管理 UART 发送流程，避免不一致的问题。

### CPU 频率调试困难

在本项目中，CPU 主频的设定是一个极具挑战的过程。由于串口通信速率较低，若 CPU 时钟过快，数据在尚未完成发送前便被刷新，极易引起信息丢失或系统错误；但若主频设置过低，又难以体现流水线并行执行的性能优势，且影响整体调试效率。

此外，硬件环境中的时序稳定性也导致很难精准预测某一频率是否“刚好足够”。这使得频率的选取过程不得不依赖大量实验，在逐步提升主频的过程中观察系统是否仍能稳定运行，反复验证是否存在异常现象，如输出乱码、丢帧等。最终我们选择了一个经验上较为稳定的频率上限（25 MHz / 50 MHz），并在此基础上构建完整的通信与调试流程。

**思考：**我们需要在这些不可控因素中找到一个“足够快又足够稳”的临界点作为妥协（即降低时钟频率）。

### 总结

通过本次项目，我们对 CPU Pipeline、指令控制、外设交互等内容有了深入理解。同时，我们也体会到现代系统设计中调试工具的重要性。借助我们自制的 UART 可视化工具链，我们成功完成了对寄存器内容、PC 值、流水线状态的实时观测与调试，为系统验证提供了重要保障。此外，在多个阶段，我们借助 AI 工具生成了测试用例、GUI 前端与反编译器原型，大幅提高了开发效率。总体而言，本项目不仅帮助我们完成了课程目标，更使我们对软硬件协同系统的工程实现过程有了更为系统性的认识。

## 8. Bonus

### 使用/开发的工具链

**主要工具：**汇编工具 RARS 搭配 Vivado，使用 UART Assist 进行测试场景切换，开发了自动适配 IP 核输入格式的脚本。开发了前端界面并集成了机器码反编译工具。
**主要用途：**辅助测试场景切换。显示寄存器值、输出和具体指令，并支持从前端输入。

**测试场景切换工具链：**运用 RARS 编写汇编代码 → 编译为十六进制机器码 → 通过脚本生成匹配的文件 → 通过 UART Assist 载入 Vivado 的 ROM 与 RAM 的 IP core → 实现测试场景切换。

**前端工具链：**运行前端脚本 → UI 中显示对应信息。

### 实现 `ecall (1,5,34,35)` 以及 `auipc`

TODO

### UART 切换测试场景

这部分使用了课件上提供的方案，即使用现成的 IP 核和串口调试助手（UartAssist）。

### 实现对复杂外设接口的支持

本项目以 UART 串口作为“软硬件协同控制复杂外设”的桥梁，实现了从 FPGA 内部 CPU 到 PC GUI 的全流程数据可视化。主要工作包括：

1. **寄存器值输出**
    在 CPU 核心中，将 32 个通用寄存器（`regs[0..31]`）和 Pipeline 各级信号（`PC, IF, ID, EXE, MEM, WB`）通过写入 `uart_output_data` 和 `data_valid_in` 等信号触发硬件端数据准备；
    硬件端的 `UartReg` 模块负责：

   - 用状态机在 `data_valid_in` 上升沿抓取新的 32-bit 数据；
   - 将其存入内部缓冲 `data_send_buffer`，拉起 `data_flag`；
   - 再驱动下层 `uart32_8` 模块按 MSB → LSB 顺序逐字节送入 `uart_tx`；
   - `uart32_8` 通过检测 `tx_busy` 生成 `tx_done` 脉冲，确保每个字节都被发送后再上升到下一个字节，最终在 4 字节全发完后输出 `signel_done`，回到空闲态。

2. **机器码反编译**
    前端 Python GUI 在接收原始 32-bit 指令字后，调用

   ```python
   inst = byte_swap_32(word)
   asm = decode_instruction(inst)
   ```

   其中：

   - `byte_swap_32` 完成字节端序校正；
   - `decode_instruction` 提取 `opcode, func3, func7, rd, rs1, rs2, imm` 等字段，并根据 R/I/S/B/U/J 型映射表拼出可读的汇编助记符（例如 `add x1, x2, x3`、`lw x4, 8(x5)`、`jal x6, 16`）。

3. **显示 CPU 输出值**
    GUI 上不仅动态更新最新接收的低 8-bit 二进制（BIN）、十进制（DEC）、十六进制（HEX）值，还以两列 16 行、斑马条纹背景的形式展示所有 32 个寄存器；右侧并排新增 Debug 区块，以单列 6 行显示 `PC, IF, ID, EXE, MEM, WB` 流水线信号。任何信号变化，标签即刻高亮提示。

4. **支持前端输入**
   用户可在 GUI 中输入 8-bit 二进制串（如 `01100101`），按回车或点击 “Send” 后，Python 端校验合法性并通过串口发送到 FPGA；
   FPGA 顶层 `UartTop` 模块中 `uart_rx` 接收器将数据写回 `cp_input`，进一步驱动硬件逻辑或点亮板上 LED，实现上—下联动。

------

**符合性说明**

此设计完全满足“软硬件协同控制复杂外设”课程标准：

- **CPU 指令驱动**：所有外设输出均由 CPU 写寄存器和有效脉冲触发，非单纯硬连线。
- **复杂外设**：串口＋GUI 可视化，支持双向交互。
- **可扩展性**：UART 序列化与反序列化、指令解码等逻辑模块化，后续可轻松加入更多寄存器或信号。

### Pipeline

我们实现的pipeline是经典的五级流水线（IF，ID，EXE，MEM，WB），参考了课本（课件）的实现方法，在单周期CPU的基础上修改后得到的。

我们把从单周期到pipeline的升级分为了两个阶段，一：重构并增加寄存器层；二：增加一些模块和逻辑，解决hazard。

#### 模块划分与寄存器层

在这一阶段，我们重新整合单周期的全部模块，并直接以流水线阶段命名，具体如下：

|        模块         |                             作用                             |
| :-----------------: | :----------------------------------------------------------: |
| **HazardDetection** |                 生成下一个要传给IF模块的pc。                 |
|       **IF**        |        输入pc，通过IM得到inst（对应单周期IFetch模块）        |
|       **ID**        | 处理inst，得到立即数，控制信号，和其他信息（对应单周期Decoder模块写回以外部分），Controller模块） |
|       **EXE**       |              进行算术运算（对应单周期ALU模块）               |
|       **FW**        | 与EXE并行，属于同一阶段，对Data Hazard进行检测并用Forwarding处理Hazard |
|       **MEM**       |         与DM通信（对应单周期DMem，WriteBackMUX模块）         |
|       **WB**        |      registers的写入模块（对应单周期Decoder写回的部分）      |

这样，这些模块就对应了pipline的各个阶段，而为了实现流水线的逻辑，我们需要在每两个相邻阶段间插入一个寄存器层，以统一的时序管理，完成数据传输，具体如下：

- IF-ID层（代码中以u1,v1前缀标明，u1代表IF阶段的输出，v1代表ID阶段的输入）；

- ID-EXE层（代码中以u2,v2前缀标明，u2代表ID阶段的输出，v2代表EXE阶段的输入）；

- EXE-MEM层（代码中以u3,v3前缀标明，u3代表EXE阶段的输出，v3代表MEM阶段的输入）；

- MEM-WB层（代码中以u4,v4前缀标明，u4代表MEM阶段的输出，v4代表WB阶段的输入）。


最后，用统一的时序控制寄存器层的传输，就完成了最基本的pipeline，时序控制为：

- 在clk上升沿，由HD模块产生新的pc给IF模块，并推动每一个寄存器层的传递（例：令vi_x <= ui_x）。
- 在clk下降沿，完成IF模块内通过IM读指令，MEM模块与DM的读写。

核心代码如下，以IF-ID层作为示例：

```verilog
always @(posedge clk, negedge rst) begin
    if(~rst)begin //reset时将指令置为NOP
            ecall_cnt <= 0;
            v1_inst <= nop_inst;
            v1_pc <= base_address;
            v1_predicted_pc <= base_address;
        end else begin
            if (en_pc2 && !is_stalling && !is_ecall) begin //在控制信号调控下进行信号传递
                if (check_predicted) begin //符合正常时序推进条件时，信号由u1传递至v1
                    ecall_cnt <= 0;
                    v1_inst <= u1_inst;
                    v1_pc <= u1_pc;
                    v1_predicted_pc <= u1_predicted_pc;
                end else begin //分支预测失败，清空当前指令为NOP
                    ecall_cnt <= 0;
                    v1_inst <= nop_inst;
                    v1_pc <= base_address;
                    v1_predicted_pc <= base_address;
                end
            end else begin //时序暂停时，v1自传递，u1信号不会传递到v1![Pipeline结构示意图](C:\Users\48946\Downloads\Pipeline结构示意图.jpg)
                ecall_cnt <= ecall_cnt ;
                v1_inst <= v1_inst;
                v1_pc <= v1_pc;
                v1_predicted_pc <= v1_predicted_pc;
            end
        end
    end
```

综合以上思路，可以得到以下结构示意图：

![Pipeline结构示意图](C:\Users\48946\Downloads\Pipeline结构示意图.jpg)

#### Data Hazard处理 - Forwarding

数据冒险(Data Hazard)是指由于指令之间存在数据依赖关系，而在流水线执行过程中导致后续指令无法获得正确数据的现象。在以上介绍的五级流水线CPU运行过程中，我们在与EXE并行的时序里增加了FW模块，用来检测可能会出现如下两种Data Hazard，并对此进行对应在硬件层面的处理：

- **Register Usage Hazard**: EXE-EXE Forwarding（前递）。
- **Load-Use Hazard**: Stalling（停顿）+MEM-EXE Forwarding（前递）

在FW模块里，我们通过比较前一条指令中rd和当前指令中的rs1/rs2来检测数据依赖，并决定参与ALU计算的两个操作数值。核心代码及说明如下：

```verilog
always @(*) begin
    //若没有数据依赖，默认操作数为ID传出的对应寄存器值
    operand1_data = rs1_data; operand2_data = rs2_data; 
    is_stalling = 0;
    if(fw_reg_write2) //前一条指令涉及到了寄存器的写回
        //检测到了load-use hazard，由MEM-EXE前递决定操作数
        if(mem_rd == rs1) operand1_data = fw_mem_data;
        if(mem_rd == rs2) operand2_data = fw_mem_data;
    if (fw_reg_write1) //前一条指令涉及到了寄存器的写回
        if(exe_rd == rs1) 
            //检测到了Register usage hazard，由EXE-EXE前递决定操作数
            if (fw_exe_have_write_data) operand1_data = fw_exe_data;
            //前一条指令中需要被写回的值仍未计算好（对应load-use hazard）此时只能停顿一个周期
            else is_stalling = 1; 
        if(exe_rd == rs2) 
            if (fw_exe_have_write_data) operand2_data = fw_exe_data;
            else is_stalling = 1;
end
```

| **输入** | **rs1** | **rs2** | **exe_rd** | **mem_rd** | **fw_exe_data** | **fw_mem_data** |
| -------- | :-----: | :-----: | :--------: | :--------: | :-------------: | :-------------: |
| **来源** |   ID    |   ID    |    EXE     |    MEM     |       EXE       |       MEM       |

#### Control Hazard处理 - 分支预测

在五级流水线 CPU 中，条件分支指令（B 类型，如 RISC-V 的 `beq`、`bne`、`blt` 等）会导致指令取（fetch）与执行（execute）之间的依赖。如果没有提前知道此类指令是“跳转”（Taken）还是“顺序执行”（Not-Taken），就必须在EXE阶段才能确定下一条指令地址，导致流水线停顿（stall）。为了解决control hazard的问题，我们分别从硬件层面和软件层面进行了尝试。

- #### 硬件层面假设跳的分支预测

  1. **产生预测：**我们在IF模块里提前判断当前指令是否为B类型指令，并产生一个预测的下一条指令的地址（predicted_pc=pc+imm32)，预测该指令将会跳转到立即数对应的地址，并将该地址加到时序中，跟随该条B指令传递。
  2. **时序推进：**当前的B指令到达了D阶段，我们读取IF预测地址对应的指令并正常运行。
  3. **检验预测是否成功：**当前B指令到达EXE阶段并确定了正确的跳转地址(true_pc)，此时可以通过比较predicted_pc和true_pc来确定预测是否成功。若预测成功，则IF、ID模块的时序继续正常推进；若预测失败，下一个时钟周期，IF和ID模块将把运行指令清空成NOP，直至再下一时钟周期跳转到正确的地址。

  EXE模块中，核心代码及说明如下：

  ```verilog
  always @(*) begin
      if (branch) begin //若该指令为B类型指令，需要检验预测
          true_pc = zero ? pc + imm32 : pc + 4;
          check_predicted = (true_pc == predicted_pc);
      end else if (is_jal) begin //若该指令为jal，需要检验预测
          true_pc = pc + imm32;
          check_predicted = (true_pc == predicted_pc);
      end else if (is_jalr) begin //若该指令为jalr，需要检验预测
          true_pc = alu_result;
          check_predicted = (true_pc == predicted_pc);
      end else begin //若该指令为其他类型指令，不需要跳转与回溯
          check_predicted = 1;
          true_pc = predicted_pc;
      end
  end
  ```

  顶层模块中，核心代码及说明如下：

  ```verilog
  wire [31:0] u1_predicted_pc; //IF模块传出来的pc预测值（若为其他指令类型则为pc+4）
  wire [31:0] true_pc; //EXE模块计算出来的真实跳转地址
  wire check_predicted; //若为0，则表示分支预测预测跳转失败
  //传入HD的指令地址，控制进入到IF的pc地址，预测失败时，需要变为由true_pc决定。
  wire [31:0] hd_input_pc = check_predicted ? u1_predicted_pc : true_pc;
  ```

- #### 软件层面仿真 CPU 行为进行分支预测编译优化

  硬件层面的动态分支预测虽然能在运行时不断调整，但是实现起来会非常复杂。为进一步提高整体性能，我们在软件层面构建了一个简化的单周期 CPU 模型，对 B 类型指令进行“统计式预测”——在执行周期里记录每条 B 类型指令实际跳转到的所有目标地址及次数，最终选出“最常见”的目标作为该指令的默认跳转地址。这一静态预测数据可以在编译后阶段用于以下优化：

  1. **指令加载：**从 `inst.txt` 读取每行 8 位小写十六进制机器码，依次映射到 PC 地址，从 `0x00003000` 开始、每条地址递增 `+4`。

  2. **仿真初始化：**初始化寄存器文件：`regs[x2]=0x00002FFC`、`regs[x3]=0x00001800`，使用 `bytearray` 模拟数据存储，为所有指令对应的 PC 在全局统计字典 `next_counts` 中创建一个空计数器（Counter）。

  3. **单周期仿真主循环**

     - **随机输入 ECALL**：对于所有 `is_ecall` 指令，随机生成 0–255 整数写入 `a0`。

     - **B 类型分支统计**：在 `fields['opcode']==B_TYPE` 时，执行

       ```python
       next_counts[pc][next_pc] += 1
       ```

       记录本次从该 `pc` 跳转到 `next_pc` 的次数，其余指令一律按顺序 `pc+4` 推进，无需统计。

  4. **默认跳转表生成**

     - 仿真结束后，对每个 `pc` 查看其 `Counter`：如果该分支被执行过，选计数最多的 `next_pc` 作为默认目标；如果从未跳转，则默认让它 `pc+4`。
     - 将所有 `(pc → 默认 next_pc)` 以八位小写十六进制格式输出到文件`log.coe` 。

  基于上述针对 B 类型指令的静态预测方法，将目标 Pipeline CPU 的超频上限从 **70 MHz** 提升到了 **75 MHz**，实现了时钟频率和整体性能的实质提升。

#### Pipeline开发过程测试说明

|                测试内容                | 测试方法 | 测试类型 |                    测试用例                    | 测试结果 |
| :------------------------------------: | :------: | :------: | :--------------------------------------------: | :------: |
| 流水线时序运行<br />（不含Hazard处理） |   上板   |   集成   |               基本测试场景一、二               |   通过   |
|            Data Hazard处理             |   上板   |   集成   |            基本测试场景二 Case3、4             |   通过   |
|           默认跳转的分支预测           |   上板   |   集成   | 基本测试场景一、二、<br />循环法求斐波那契数列 |   通过   |
|       软件仿真编译优化的分支预测       |   上板   |   集成   | 基本测试场景一、二、<br />循环法求斐波那契数列 |   通过   |

#### Pipeline相对于单周期CPU的性能提升

针对于同一测试用例（循环法求第10^7项斐波那契数），我们分别在单周期CPU、硬件实现分支预测的Pipeline CPU以及软件编译优化的Pipeline CPU上进行了测试，同时记录运行所需要的周期数，结果如下：

|             CPU             | 时钟频率 | 运行周期总数 | 运行时长 |
| :-------------------------: | :------: | :----------: | :------: |
|    Single Cycle - 单周期    |  25MHz   |  50,000,006  |  2.000s  |
| Pipeline - 硬件实现分支预测 |  70MHz   |  50,000,017  |  0.714s  |
|   Pipeline - 软件编译优化   |  75MHz   |  50,000,015  |  0.667s  |

由测试结果可知，Pipeline相对于单周期CPU主要表现出时钟频率的大幅提升，而CPI基本持平，进而实现了运行时长的大幅减少，进而实现了性能提升。
