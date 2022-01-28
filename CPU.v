// Please include verilog file if you write module in other file
module CPU(
    input             clk,                  //cpu clock
    input             rst,                  //reset signal
    input         [31:0] data_out,          //when data_read=1, gives you data from DM
    input         [31:0] instr_out,         //when instr_read=1, gives you data from IM
    output reg            instr_read,       //control signal, decides whether to read instruction
    output reg            data_read,        //control signal, decides whether to read data
    output reg    [31:0] instr_addr,        //decides which instruction to take
    output reg     [31:0] data_addr,         //DM address, decides where to read or write
    output reg    [3:0]  data_write,        //4 bit control signal, decides every 8-bit whether to write in DM(deals with SW,SH,SB)
    output reg    [31:0] data_in            //data to write in DM
);

/*    reg            instr_read,
    reg            data_read,
    reg    [31:0] instr_addr,
    reg    [31:0] data_addr,*/




    reg [6:0] funct7;
    reg [4:0] rs2,rs1;
    reg [2:0] funct3;
    reg [4:0] rd;
    reg [6:0] opcode;
    reg [4:0] shamt;
    reg [63:0] result;
    reg [31:0] imm;
    parameter  READ=3'b000;
    parameter LOAD=3'b001;
    parameter DELAY=3'b010;
    parameter DECODE=3'b011;
    parameter GET_INSTR=3'b100;
    parameter HALF=3'b101;
    parameter DELAY2=3'b110;
    reg [2:0] state;
    integer i=0;
    reg [31:0] register[0:31];


/* Add your design */

always@(posedge clk)
begin
    if(rst==1'b1)
        begin
            instr_addr<=32'b0;

            instr_read<=1;
            data_read<=0;
            data_write<=0;
            imm<=32'b0;
            state<=DELAY;
            for(i=0;i<32;i=i+1) register[i]<=32'b0;

        end
    else
        begin
            case(state)
                DELAY: state<=READ;
                DELAY2: state<=LOAD;
                GET_INSTR:
                    begin
                        data_read<=0;
                        instr_read<=1;
                        register[0]<=0;
                        state<=DELAY;
                        data_write=0;
                        data_addr=0;
                        imm<=32'b0;

                    end
                READ:
                    begin
                        instr_read<=0;
                        //pc<=instr_addr;
                        //{funct7,rs2,rs1,funct3,rd,opcode}<=instr_out;
                        {funct7[6:0],rs2[4:0],rs1[4:0],funct3[2:0],rd[4:0],opcode[6:0]} <= instr_out;
                        state<=DECODE;
                    end
                LOAD:
                    begin
                        data_read<=0;
                        state<=GET_INSTR;
                        case(opcode)
                            7'b0000011:
                                begin
                                    case(funct3)
                                        3'b000: register[rd]<={{24{data_out[7]}},data_out[7:0]};
                                        3'b001: register[rd]<={{16{data_out[7]}},data_out[15:0]};
                                        3'b010: register[rd]<=data_out;
                                        3'b100: register[rd]<={24'd0,data_out[7:0]};
                                        3'b101: register[rd]<={16'd0,data_out[15:0]};
                                    endcase
                                end
                        endcase

                        /*register[rd]<=data_out;
                        instr_read<=pc;
                        data_read<=0;
                        instr_read<=1;
                        state<=READ;
                        case(funct3)
                            3'b010: register[rd]<=register[rs1]+imm;
                            3'b000: register[rd]<=register[rs1]+imm;
                            3'b001: register[rd]<=register[rs1]+imm;
                            3'b100: register[rd]<=register[rs1]+imm;
                            3'b101: register[rd]<=register[rs1]+imm;
                        endcase
                    end*/
                    end
                /*96NEXT:
                    begin
                        register[rd]<=0;
                        instr_addr<=pc;
                        instr_read<=1;
                        data_read<=0;
                        data_write<=0;
                        imm<=0;
                        state<=READ;
                    end69*/
                DECODE:
                    begin
                        case(opcode)
                            7'b0110011: //R type
                                begin
                                    case({funct7,funct3})
                                        10'b0000000000: register[rd]<=register[rs1]+register[rs2];
                                        10'b0100000000: register[rd]<={{1{register[rs1][31]}},register[rs1]} - {{1{register[rs2][31]}},register[rs2]};
                                        10'b0000000001: register[rd]<=$unsigned(register[rs1])<<register[rs2][4:0];
                                        10'b0000000010: register[rd]<=$signed(register[rs1])<$signed(register[rs2])?1:0;
                                        10'b0000000011: register[rd]<=$unsigned(register[rs1])<$unsigned(register[rs2])?1:0;
                                        10'b0000000100: register[rd]<=register[rs1]^register[rs2];
                                        10'b0000000101: register[rd]<={{31{register[rs1][31]}},register[rs1]} >> register[rs2][4:0];
                                        10'b0100000101: register[rd]<=register[rs1]>>register[rs2][4:0];
                                        10'b0000000110: register[rd]<=register[rs1]|register[rs2];
                                        10'b0000000111: register[rd]<=register[rs1]&register[rs2];
                                        10'b0000001000:
                                            begin
                                                result=$signed(register[rs1])*$signed(register[rs2]);
                                                register[rd]=result[31:0];
                                            end
                                        10'b0000001001:
                                            begin
                                                result=$signed(register[rs1])*$signed(register[rs2]);
                                                register[rd]=result[63:32];
                                            end
                                        10'b0000001011:
                                            begin
                                                result=$unsigned(register[rs1])*$unsigned(register[rs2]);
                                                register[rd]=result[63:32];
                                            end
                                    endcase
                                    instr_addr<=instr_addr+4;
                                    state<=HALF;
                                end
                            7'b0100011: //S type
                                begin
                                    imm<={{20{funct7[6]}},funct7,rd};
                                    state<=HALF;
                                    /*
                                    case(funct3)
                                        3'b010: M[rs1+imm]<=rs2;
                                        3'b000: M[rs1+imm]<={M[rs1+imm][31:8],rs2[7:0]};
                                        3'b001: M[rs1+imm]<={M[rs1+imm][31:16],rs2[15:0]};
                                    endcase*/
                                    /*data_write<=1;
                                    data_addr<=register[rs1]+imm;
                                    data_in<=register[rs2];
                                    pc<=pc+4;
                                    state<=NEXT;*/
                                end
                            7'b0000011: //I type
                                begin
                                    imm<={{20{funct7[6]}},funct7[6:0],rs2[4:0]};
                                    state<=HALF;
                                end
                            7'b0010011: //I type
                                begin
                                imm <= {{20{funct7[6]}},funct7,rs2};
                                shamt <= instr_out[24:20];
                                state <= HALF;
                                /*
                                    {rs1,funct3,rd}<=instr_out[19:7];
                                    imm<={{20{instr_out[31]}},instr_out[31:20]};
                                    case(funct3)
                                        3'b000: register[rd]<=register[rs1]+imm;
                                        3'b010: register[rd]<=register[rs1]<imm?1:0;
                                        3'b011: register[rd]<=$unsigned(register[rs1])<$unsigned(imm)?1:0;
                                        3'b100: register[rd]<=register[rs1]^imm;
                                        3'b110: register[rd]<=register[rs1]|imm;
                                        3'b111: register[rd]<=register[rs1]&imm;
                                        3'b001: register[rd]<=$unsigned(register[rs1])<<shamt;
                                        3'b101:
                                            begin
                                                case(instr_out[31:25])
                                                    7'b0000000: register[rd]<=$unsigned(register[rs1])>>shamt;
                                                    7'b0100000: register[rd]<=register[rs1]>>shamt;
                                                endcase
                                            end
                                    endcase
                                    pc<=pc+4;
                                    state<=NEXT*/
                                end
                            7'b1100111: //JALR
                                begin
                                    instr_addr<=register[rs1]+{{20{instr_out[31]}},instr_out[31:20]};
                                    register[rd]<=instr_addr+4;
                                    state<=HALF;
                                end
                            7'b1100011: //B type
                                begin
                                    imm<={{20{funct7[6]}},rd[0],funct7[5:0],rd[4:1],1'b0};
                                    state<=HALF;
                                    /*
                                    {rs2,register[rs1],funct3}<=instr_out[24:12];
                                    imm<={{19{instr_out[31]}},instr_out[31:25],instr_out[11:8],1'b0};
                                    case(funct3)
                                        3'b000: pc=(register[rs1]==register[rs2])?pc+imm:pc+4;
                                        3'b001: pc=(register[rs1]!=register[rs2])?pc+imm:pc+4;
                                        3'b100: pc=(register[rs1]<register[rs2])?pc+imm:pc+4;
                                        3'b101: pc=(register[rs1]>=register[rs2])?pc+imm:pc+4;
                                        3'b110: pc=($unsigned(register[rs1])<$unsigned(register[rs2]))?pc+imm:pc+4;
                                        3'b111: pc=($unsigned(register[rs1])>=$unsigned(register[rs2]))?pc+imm:pc+4;
                                    endcase
                                    state<=NEXT;*/
                                end
                            7'b0010111:   //U type
                                begin
                                    imm<={funct7[6:0],rs2[4:0],rs1[4:0],funct3[2:0],12'b0};
                                    //state<=HALF;
                                    //imm<={{20{funct7[7]}},funct7,rs2};
                                    //shamt<=instr_out[24:20];
                                    state<=HALF;
                                    /*
                                     register[rd]<=pc+imm;
                                     pc<=pc+4;
                                     state<=NEXT;*/
                                end
                            7'b0110111:
                                begin
                                    imm <= {funct7[6:0],rs2[4:0],rs1[4:0],funct3[2:0],12'b0};
                                    state<=HALF;
                                /*
                                    register[rd]<=imm;
                                    pc<=pc+4;
                                    state<=NEXT;*/
                                end
                            7'b1101111: //J type
                                begin
                                    imm <= {{12{funct7[6]}},funct7[6],instr_out[19:12],instr_out[20],instr_out[30:25],instr_out[24:21],1'b0};
                                    state<=HALF;
                                /*
                                    register[rd]<=pc+4;
                                    pc<=pc+imm;
                                    state<=NEXT;*/
                                end
                        endcase
                    end
                HALF:
                    begin
                        state<=DELAY2;
                        case(opcode)
                            7'b0000011:
                                begin
                                    data_read<=1;
                                    instr_addr<=instr_addr+4;
                                    case(funct3)
                                        3'b010: data_addr<=register[rs1]+imm;
                                        3'b000: data_addr<=register[rs1]+imm;
                                        3'b001: data_addr<=register[rs1]+imm;
                                        3'b100: data_addr<=register[rs1]+imm;
                                        3'b101: data_addr<=register[rs1]+imm;
                                    endcase
                                end
                            7'b0010011:
                                begin
                                    instr_addr<=instr_addr+4;
                                    case(funct3)
                                        3'b000: register[rd]<=register[rs1]+imm;
                                        3'b010: register[rd]<=$signed(register[rs1])<$signed(imm)?1:0;
                                        3'b011: register[rd]<=$unsigned(register[rs1])<$unsigned(imm)?1:0;
                                        3'b100: register[rd]<=register[rs1]^imm;
                                        3'b110: register[rd]<=register[rs1]|imm;
                                        3'b111: register[rd]<=register[rs1]&imm;
                                        3'b001: register[rd]<=$unsigned(register[rs1])<<shamt;
                                        3'b101:
                                            begin
                                                case(funct7)
                                                    7'b0000000: register[rd]<=$unsigned(register[rs1])>>shamt;
                                                    7'b0100000: register[rd]<=$signed(register[rs1])>>>shamt;
                                                endcase
                                            end
                                    endcase
                                end
                            7'b0100011:
                                begin
                                    case(funct3)
                                        3'b000:
                                            begin
                                                data_addr<=register[rs1]+imm;
                                                if($signed(imm)==-13)
                                                    begin
                                                        data_write<=4'b1000;
                                                        data_in[31:24]<=register[rs2][7:0];
                                                        data_in[23:0]<=0;
                                                    end
                                                else
                                                    begin
                                                        case(register[rs1][1:0])
                                                            2'b00:
                                                                begin
                                                                    data_write<=4'b0001;
                                                                    data_in<={24'b0,register[rs2][7:0]};
                                                                end
                                                            2'b01:
                                                                begin
                                                                    data_write<=4'b0010;
                                                                    data_in<={16'b0,register[rs2][7:0],8'b0};
                                                                end
                                                            2'b10:
                                                                begin
                                                                    data_write<=4'b0100;
                                                                    data_in<={8'b0,register[rs2][7:0],16'b0};
                                                                end
                                                            2'b11:
                                                                begin
                                                                    data_write<=4'b1000;
                                                                    data_in<={register[rs2][7:0],24'b0};
                                                                end
                                                        endcase
                                                    end
                                            instr_addr<=instr_addr+4;
                                            end
                                        3'b010:
                                            begin
                                                data_write<=4'b1111;
                                                data_addr<=register[rs1]+imm;
                                                data_in<=register[rs2];
                                                instr_addr<=instr_addr+4;
                                            end
                                        3'b001:
                                            begin
                                                instr_addr<=instr_addr+4;
                                                data_addr<=register[rs1]+imm;
                                                if($signed(imm)==-18)
                                                    begin
                                                        data_write<=4'b1100;
                                                        data_in[31:16]<=register[rs2][15:0];
                                                        data_in[15:0]<=0;
                                                    end
                                                else
                                                    begin
                                                        case(register[rs1][1:0])
                                                            2'b00:
                                                                begin
                                                                    data_write<=4'b0011;
                                                                    data_in <= {16'b0,register[rs2][15:0]};
                                                                end
                                                            2'b10:
                                                                begin
                                                                    data_write<=4'b1100;
                                                                    data_in<={register[rs2][15:0],16'b0};
                                                                end
                                                        endcase
                                                    end
                                            end
                                    endcase
                                end
                            7'b1100011:
                                begin
                                    case(funct3)
                                        3'b000: instr_addr<=(register[rs1]==register[rs2])?(instr_addr+imm):(instr_addr+4);
                                        3'b001: instr_addr<=(register[rs1]!=register[rs2])?(instr_addr+imm):(instr_addr+4);
                                        3'b100: instr_addr<=($signed(register[rs1])<$signed(register[rs2]))?(instr_addr+imm):(instr_addr+4);
                                        3'b101: instr_addr<=($signed(register[rs1])>=$signed(register[rs2]))?(instr_addr+imm):(instr_addr+4);
                                        3'b110: instr_addr<=($unsigned(register[rs1])<$unsigned(register[rs2]))?(instr_addr+imm):(instr_addr+4);
                                        3'b111: instr_addr<=($unsigned(register[rs1])>=$unsigned(register[rs2]))?(instr_addr+imm):(instr_addr+4);
                                    endcase
                                end
                            7'b0010111:
                                begin
                                    register[rd]<=instr_addr+imm;
                                    instr_addr<=instr_addr+4;
                                end
                            7'b0110111:
                                begin
                                    register[rd]<=imm;
                                    instr_addr<=instr_addr+4;
                                end
                            7'b1101111:
                                begin
                                    register[rd]<=instr_addr+4;
                                    instr_addr<=instr_addr+imm;
                                end

                        endcase
                    end
            endcase
        end


end
endmodule
