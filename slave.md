
# Entity: slave 
- **File**: slave.v

## Diagram
![Diagram](docs/slave.jpg "Diagram")
## Generics

| Generic name | Type | Value | Description |
| ------------ | ---- | ----- | ----------- |
| DATA_WIDTH   |      | 32    |             |
| ADDR_WIDTH   |      | 32    |             |

## Ports

| Port name | Direction | Type                               | Description |
| --------- | --------- | ---------------------------------- | ----------- |
| clk       | input     |                                    |             |
| rst_n     | input     |                                    |             |
| awaddr    | input     | [ADDR_WIDTH-1:0]                   |             |
| awburst   | input     | [7:0]                              |             |
| awvalid   | input     |                                    |             |
| awready   | output    |                                    |             |
| wdata     | input     | [DATA_WIDTH-1:0]                   |             |
| wstrb     | input     | [clog2(DATA_WIDTH)-2:0]            |             |
| wvalid    | input     |                                    |             |
| wready    | output    |                                    |             |
| bresp     | output    | [1:0]                              |             |
| bvalid    | output    |                                    |             |
| bready    | input     |                                    |             |
| araddr    | input     | [ADDR_WIDTH-1:0]                   |             |
| arburst   | input     | [7:0]                              |             |
| arvalid   | input     |                                    |             |
| arready   | output    |                                    |             |
| rdata     | output    | [DATA_WIDTH-1:0]                   |             |
| rresp     | output    | [1:0]                              |             |
| rvalid    | output    |                                    |             |
| rready    | input     |                                    |             |
| tx_full   | input     |                                    |             |
| tx_wr_en  | output    |                                    |             |
| tx_data   | output    | [DATA_WIDTH+clog2(DATA_WIDTH)-2:0] |             |
| rx_empty  | input     |                                    |             |
| rx_rd_en  | output    |                                    |             |
| rx_data   | input     | [DATA_WIDTH-1:0]                   |             |

## Signals

| Name          | Type                    | Description |
| ------------- | ----------------------- | ----------- |
| ctrl          | reg [DATA_WIDTH-1:0]    |             |
| status        | reg [DATA_WIDTH-1:0]    |             |
| wr_en_waddr   | wire                    |             |
| rd_en_waddr   | reg                     |             |
| full_waddr    | wire                    |             |
| empty_waddr   | wire                    |             |
| wr_data_waddr | wire [ADDR_WIDTH+8-1:0] |             |
| rd_data_waddr | wire [ADDR_WIDTH+8-1:0] |             |
| state         | reg [1:0]               |             |
| burstcnt      | reg [7:0]               |             |
| wr_addr       | reg [ADDR_WIDTH-1:0]    |             |
| resp_rg       | reg [1:0]               |             |
| wr_en_raddr   | reg                     |             |
| rd_en_raddr   | reg                     |             |
| full_raddr    | wire                    |             |
| empty_raddr   | wire                    |             |
| wr_data_raddr | reg [ADDR_WIDTH+8-1:0]  |             |
| rd_data_raddr | wire [ADDR_WIDTH+8-1:0] |             |
| r_state       | reg                     |             |
| r_burstcnt    | reg [7:0]               |             |
| rd_addr       | reg [ADDR_WIDTH-1:0]    |             |
| rresp_rg      | reg [1:0]               |             |

## Constants

| Name   | Type | Value | Description |
| ------ | ---- | ----- | ----------- |
| IDLE   |      | 2'b00 |             |
| WRITE  |      | 2'b01 |             |
| RESP   |      | 2'b10 |             |
| R_IDLE |      | 1'b0  |             |
| R_READ |      | 1'b1  |             |

## Processes
- unnamed: ( @(posedge clk) )
  - **Type:** always
- unnamed: ( @(posedge clk or negedge rst_n) )
  - **Type:** always
- unnamed: ( @(posedge clk or negedge rst_n) )
  - **Type:** always
- unnamed: ( @(posedge clk or negedge rst_n) )
  - **Type:** always
- unnamed: ( @(posedge clk or negedge rst_n) )
  - **Type:** always

## Instantiations

- waddr_fifo: sync_fifo
- raddr_fifo: sync_fifo

## State machines

![Diagram_state_machine_0]( docs/fsm_slave_00.jpg "Diagram")![Diagram_state_machine_1]( docs/fsm_slave_11.jpg "Diagram")