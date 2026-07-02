class transaction;
  rand bit din;
  bit dout;
  
  /////create deep copy of the transaction class 
  function transaction copy();
    copy=new();
    copy.din=this.din;
    copy.dout=this.dout;
  endfunction
  
  /////create function to display transaction information
  function void display(input string tag);
    $display("[%0s] : \t din:%0b \t dout:%0b",tag, din, dout);
  endfunction
  
endclass

/////generator class -> Generates random stimuli for verification

class generator;
  
  transaction tr; // handler for transaction class
  mailbox #(transaction) mbx; //to send generated stimuli to driver 
  mailbox #(transaction) mbxref; //to send generated stimuli to scoreboard for comparison 
  event sconext; //to sense completion of scoreboard comparison
  event done; //to trigger when completion of generating stimuli
  int count; //to count no of stimulus->> updated in tb top
  
  function new( mailbox #(transaction) mbx,mailbox #(transaction) mbxref);
    this.mbx=mbx;
    this.mbxref=mbxref;
    tr=new();
  endfunction
  
  task run();
    repeat(count) begin
      assert(tr.randomize) else $error("[GEN]: Randomization failed");
      mbx.put(tr.copy);  //put copy of transaction to driver
      mbxref.put(tr.copy); //put copy of transaction to scoreborad
      tr.display("GEN");
      @(sconext); // wait for scoreboard's completion signal
    end
    ->done; //trigger done when all stimuli are applied
  endtask 
endclass

/////driver class-> recieve data from generator and apply it to DUT

class driver;
  transaction tr;
  mailbox #(transaction) mbx;
  
  virtual dff_if vif;
  
  function new(mailbox #(transaction) mbx);
    this.mbx=mbx;
  endfunction
  
  task reset();
    vif.rst <= 1'b1;
    repeat(5) @(posedge vif.clk);
    vif.rst <= 1'b0;
    @(posedge vif.clk);
    $display("[drv]: Reset Done");
  endtask
  
  task run();
    forever begin
      mbx.get(tr); //recieve data from generator
      vif.din <= tr.din;
      @(posedge vif.clk); //wait for 1 clk cycle 
      tr.display("DRV");
      vif.din <= 1'b0;
      @(posedge vif.clk); //wait for another cycle -- total 2 clk cycles in driver 
    end
  endtask
endclass

///////monitor class-> captures output from DUT and send it to scoreboard

class monitor;
  transaction tr;
  mailbox #(transaction) mbx;
  
  virtual dff_if vif;
  
  function new(mailbox #(transaction) mbx);
    this.mbx=mbx;
  endfunction
  
  task run();
    tr = new();
    forever begin
      repeat(2) @(posedge vif.clk); // wait for 2 clk cycles   
      tr.dout = vif.dout; //capture op data of dut imp-->> use blocking assignment operator
      mbx.put(tr); //capturd data to scoreboard
      tr.display("MON");
    end 
  endtask
endclass

////scoreboard class--> for comparison of data rcvd from generator and output of dut rcvd from monitor

class scoreboard;
  transaction tr;
  transaction trref; // reference transaction object for comparison
  mailbox #(transaction) mbx; //to recieve data from monitor
  mailbox #(transaction) mbxref; // to recieve dta from generator
  event sconext; //to sense completion of scoreboard work
  
  function new( mailbox #(transaction) mbx,mailbox #(transaction) mbxref);
    this.mbx=mbx;
    this.mbxref=mbxref;
  endfunction
  
  task run();
    forever begin
      mbx.get(tr); 
      mbxref.get(trref); 
      tr.display("SCO");
      trref.display("REF");
    
      if (tr.dout == trref.din)
        $display("[SCO]:DATA MATCHED");
      else
        $display("[SCO]:DATA MISMATCHED");
      $display("-----------------------------------------------------");
      ->sconext;
      
    
    end
  endtask
endclass


////class environment-> to connect all components and executing parallel operation 

class environment;
  generator gen; 
  driver drv;
  monitor mon;
  scoreboard sco;
  event next;
  
  mailbox #(transaction) gdmbx;
  mailbox #(transaction) msmbx;
  mailbox #(transaction) mbxref;
  
  virtual dff_if vif;
  
  function new(virtual dff_if vif);
    gdmbx=new();
    mbxref=new();
    gen=new(gdmbx,mbxref);
    drv=new(gdmbx);
    msmbx=new();
    mon=new(msmbx);
    sco=new(msmbx,mbxref);
    this.vif=vif;
    drv.vif=this.vif;
    mon.vif=this.vif;
    gen.sconext=next;
    sco.sconext=next;
  endfunction
  
  task pre_test();
    drv.reset();
  endtask
  
  task test();
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_any
  endtask
  
  task post_test();
    wait(gen.done.triggered);
    $finish();
  endtask
  
  task run();
    pre_test();
    test();
    post_test();
  endtask
  
  
endclass

//////////top testbench module

module tb;
  dff_if vif(); //create DUT interface
  dff dut(vif); //instantiate DUT
  
  initial begin
    vif.clk <= 0; //initialize clk signal
  end
  
  always #10 vif.clk <= ~vif.clk; //toggle clk every 10 ns
  
  environment env;
  
  initial begin
    env=new(vif);
    env.gen.count = 30;
    env.run();
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
endmodule
