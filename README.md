# riscv_cpu

使用FSM的概念來完成整個CPU的運作 

主要的波形解釋如下：

data_out：data_read = 1時會給來自DM的資料

instr_out：instr_read = 1時會給來自IM的資料

instr_read：決定要不要讀instruction進來

data_read：決定要不要讀data進來

instr_addr：instrunction的address

data_addr：決定讀或寫DM上的哪一個位置

data_write：決定哪些bit要寫入DM

data_in：要寫入DM的資料
