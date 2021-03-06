-- Author: JL
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

---------------------------------------------
entity Demod_preCR is
	generic(
		kInSize : positive := 8;
		kDataWidth : positive := 8 );
	port (
		aReset          : in  std_logic;
		clk_100         : in  std_logic;
		pclk_I			: in  std_logic;  -- 50MHz
		rclk           : in std_logic ; --75MHZ
		rclk_half		: in std_logic; -- 37.5MHz

		AD_d0			: in std_logic_vector(kInSize-1 downto 0);
		AD_d1			: in std_logic_vector(kInSize-1 downto 0);
		AD_d2			: in std_logic_vector(kInSize-1 downto 0);
		AD_d3           : in std_logic_vector(kInSize-1 downto 0);
		AD_d4			: in std_logic_vector(kInSize-1 downto 0);
		AD_d5           : in std_logic_vector(kInSize-1 downto 0);
		AD_d6           : in std_logic_vector(kInSize-1 downto 0);
		AD_d7           : in std_logic_vector(kInSize-1 downto 0);

		sInPhaseOut0      : out signed(kDataWidth-1 downto 0);
    sInPhaseOut1      : out signed(kDataWidth-1 downto 0);
    sInPhaseOut2      : out signed(kDataWidth-1 downto 0);
    sInPhaseOut3      : out signed(kDataWidth-1 downto 0);
    sQuadPhaseOut0    : out signed(kDataWidth-1 downto 0);
    sQuadPhaseOut1    : out signed(kDataWidth-1 downto 0);
    sQuadPhaseOut2    : out signed(kDataWidth-1 downto 0);
    sQuadPhaseOut3    : out signed(kDataWidth-1 downto 0);
    sEnableOut        : out std_logic;

		RSSI_out 					: out std_logic_vector(7 downto 0)

     );
end Demod_preCR;

architecture rt1 of Demod_preCR is

	component DownConvert is
    generic (
      kInSize      : positive := 12;
      kOutSize     : positive := 12;
      kNCOSize	   : positive := 16
     );
    port (
		--mode : in std_logic_vector(1 downto 0);
      aReset            : in std_logic;
      clk               : in std_logic;
      AD_sample0        : in std_logic_vector (kInsize-1 downto 0);
	  AD_sample1        : in std_logic_vector (kInsize-1 downto 0);
	  AD_sample2        : in std_logic_vector (kInsize-1 downto 0);
	  AD_sample3        : in std_logic_vector (kInsize-1 downto 0);
	  AD_sample4        : in std_logic_vector (kInsize-1 downto 0);
	  AD_sample5        : in std_logic_vector (kInsize-1 downto 0);
	  AD_sample6        : in std_logic_vector (kInsize-1 downto 0);
	  AD_sample7        : in std_logic_vector (kInsize-1 downto 0);

	  InPhase0			: out std_logic_vector (kOutsize-1 downto 0);
	  InPhase1			: out std_logic_vector (kOutsize-1 downto 0);
	  InPhase2			: out std_logic_vector (kOutsize-1 downto 0);
	  InPhase3			: out std_logic_vector (kOutsize-1 downto 0);
	  InPhase4			: out std_logic_vector (kOutsize-1 downto 0);
	  InPhase5			: out std_logic_vector (kOutsize-1 downto 0);
	  InPhase6			: out std_logic_vector (kOutsize-1 downto 0);
	  InPhase7			: out std_logic_vector (kOutsize-1 downto 0);

	  QuadPhase0		: out std_logic_vector (kOutsize-1 downto 0);
	  QuadPhase1		: out std_logic_vector (kOutsize-1 downto 0);
	  QuadPhase2		: out std_logic_vector (kOutsize-1 downto 0);
	  QuadPhase3		: out std_logic_vector (kOutsize-1 downto 0);
	  QuadPhase4		: out std_logic_vector (kOutsize-1 downto 0);
	  QuadPhase5		: out std_logic_vector (kOutsize-1 downto 0);
	  QuadPhase6		: out std_logic_vector (kOutsize-1 downto 0);
	  QuadPhase7		: out std_logic_vector (kOutsize-1 downto 0)
     );
	end component;

	component TimerecoveryP8_v2 is
        generic (
                kDecimateRate   : positive := 13; -- bit width of Fraction decimate
                kCountWidth     : positive := 4;  -- bit width of the Counter,it is used in Interpolator.(attention: this parameter must be 4 under 8 parallel condition)
                kDelay          : positive :=10;   -- delay of the Interpolate Controller.
                kDataWidth      : positive :=8;
                kErrorWidth     : positive :=16;
                kKpSize         : positive :=3;
                kKiSize         : positive :=3);  -- bit width of the input data.
        port (
                aReset          : in std_logic;
                Clk_in          : in std_logic;
                sEnable         : in std_logic;

                sDataInPhase0   : in signed (kDataWidth-1 downto 0);
                sDataInPhase1   : in signed (kDataWidth-1 downto 0);
                sDataInPhase2   : in signed (kDataWidth-1 downto 0);
                sDataInPhase3   : in signed (kDataWidth-1 downto 0);
                sDataInPhase4   : in signed (kDataWidth-1 downto 0);
                sDataInPhase5   : in signed (kDataWidth-1 downto 0);
                sDataInPhase6   : in signed (kDataWidth-1 downto 0);
                sDataInPhase7   : in signed (kDataWidth-1 downto 0);

                sDataQuadPhase0   : in signed (kDataWidth-1 downto 0);
                sDataQuadPhase1   : in signed (kDataWidth-1 downto 0);
                sDataQuadPhase2   : in signed (kDataWidth-1 downto 0);
                sDataQuadPhase3   : in signed (kDataWidth-1 downto 0);
                sDataQuadPhase4   : in signed (kDataWidth-1 downto 0);
                sDataQuadPhase5   : in signed (kDataWidth-1 downto 0);
                sDataQuadPhase6   : in signed (kDataWidth-1 downto 0);
                sDataQuadPhase7   : in signed (kDataWidth-1 downto 0);

                -- recovered symbols
                sInPhaseOut0      : out signed(kDataWidth-1 downto 0);
                sInPhaseOut1      : out signed(kDataWidth-1 downto 0);
                sInPhaseOut2      : out signed(kDataWidth-1 downto 0);
                sInPhaseOut3      : out signed(kDataWidth-1 downto 0);
                sQuadPhaseOut0    : out signed(kDataWidth-1 downto 0);
                sQuadPhaseOut1    : out signed(kDataWidth-1 downto 0);
                sQuadPhaseOut2    : out signed(kDataWidth-1 downto 0);
                sQuadPhaseOut3    : out signed(kDataWidth-1 downto 0);
                sEnableOut        : out std_logic);
		--				sLockSign		  : out std_logic);
	end   component;

	component	LPF_P8_D2	is
	 generic(
		kInSize  : positive :=12;
		kOutSize : positive :=8);
port(
		aReset	: in std_logic;
		Clk		: in std_logic;
		cDin0	: in std_logic_vector(kInSize-1 downto 0);
		cDin1	: in std_logic_vector(kInSize-1 downto 0);
		cDin2	: in std_logic_vector(kInSize-1 downto 0);
		cDin3	: in std_logic_vector(kInSize-1 downto 0);
		cDin4	: in std_logic_vector(kInSize-1 downto 0);
		cDin5	: in std_logic_vector(kInSize-1 downto 0);
		cDin6	: in std_logic_vector(kInSize-1 downto 0);
		cDin7	: in std_logic_vector(kInSize-1 downto 0);
		cDout0	: out std_logic_vector(kOutSize-1 downto 0);
		cDout1	: out std_logic_vector(kOutSize-1 downto 0);
		cDout2	: out std_logic_vector(kOutSize-1 downto 0);
		cDout3	: out std_logic_vector(kOutSize-1 downto 0)
		);
end	component;

component	P4toP8_8	is
	 generic(
		kDataWidth  : positive :=8 );
port(
		aReset	: in std_logic;
		clk_in		: in std_logic;
		clk_out		: in std_logic;
		data_in1		: in std_logic_vector(kDataWidth-1 downto 0);
		data_in2		: in std_logic_vector(kDataWidth-1 downto 0);
		data_in3		: in std_logic_vector(kDataWidth-1 downto 0);
		data_in4		: in std_logic_vector(kDataWidth-1 downto 0);
		valid_in	: in std_logic;

		data_out1		: out std_logic_vector(kDataWidth-1 downto 0);
		data_out2		: out std_logic_vector(kDataWidth-1 downto 0);
		data_out3		: out std_logic_vector(kDataWidth-1 downto 0);
		data_out4		: out std_logic_vector(kDataWidth-1 downto 0);
		data_out5		: out std_logic_vector(kDataWidth-1 downto 0);
		data_out6		: out std_logic_vector(kDataWidth-1 downto 0);
		data_out7		: out std_logic_vector(kDataWidth-1 downto 0);
		data_out8		: out std_logic_vector(kDataWidth-1 downto 0);
		valid_out	: out std_logic
		);
end	component;

component	shapingfilter_p8	is
	 generic(
		kInSize  : positive :=8;
		kOutSize : positive :=8);
port(
		aReset	: in std_logic;
		Clk		: in std_logic;
		cDin0	: in std_logic_vector(kInSize-1 downto 0);
		cDin1	: in std_logic_vector(kInSize-1 downto 0);
		cDin2	: in std_logic_vector(kInSize-1 downto 0);
		cDin3	: in std_logic_vector(kInSize-1 downto 0);
		cDin4	: in std_logic_vector(kInSize-1 downto 0);
		cDin5	: in std_logic_vector(kInSize-1 downto 0);
		cDin6	: in std_logic_vector(kInSize-1 downto 0);
		cDin7	: in std_logic_vector(kInSize-1 downto 0);
		cDout0	: out std_logic_vector(kOutSize-1 downto 0);
		cDout1	: out std_logic_vector(kOutSize-1 downto 0);
		cDout2	: out std_logic_vector(kOutSize-1 downto 0);
		cDout3	: out std_logic_vector(kOutSize-1 downto 0);
		cDout4	: out std_logic_vector(kOutSize-1 downto 0);
		cDout5	: out std_logic_vector(kOutSize-1 downto 0);
		cDout6	: out std_logic_vector(kOutSize-1 downto 0);
		cDout7	: out std_logic_vector(kOutSize-1 downto 0)
		);
end	component;

component RSSI_p4 is
  generic (
  kInSize : positive := 8;
  kOutsize: positive := 8
  );
  port (
  aReset  : in std_logic;
  clk     : in std_logic;

	d_in_I0  : in std_logic_vector(kInSize-1 downto 0);
  d_in_I1  : in std_logic_vector(kInSize-1 downto 0);
  d_in_I2  : in std_logic_vector(kInSize-1 downto 0);
  d_in_I3  : in std_logic_vector(kInSize-1 downto 0);
  d_in_I4  : in std_logic_vector(kInSize-1 downto 0);
  d_in_I5  : in std_logic_vector(kInSize-1 downto 0);
  d_in_I6  : in std_logic_vector(kInSize-1 downto 0);
  d_in_I7  : in std_logic_vector(kInSize-1 downto 0);
  d_in_Q0  : in std_logic_vector(kInSize-1 downto 0);
  d_in_Q1  : in std_logic_vector(kInSize-1 downto 0);
  d_in_Q2  : in std_logic_vector(kInSize-1 downto 0);
  d_in_Q3  : in std_logic_vector(kInSize-1 downto 0);
  d_in_Q4  : in std_logic_vector(kInSize-1 downto 0);
  d_in_Q5  : in std_logic_vector(kInSize-1 downto 0);
  d_in_Q6  : in std_logic_vector(kInSize-1 downto 0);
  d_in_Q7  : in std_logic_vector(kInSize-1 downto 0);
  val_in   : in std_logic;

  rssi_out  : out std_logic_vector(kOutsize-1 downto 0)


  );
end component;

	signal  Dclk_rst : std_logic;

	type InputDataArray is array (natural range  <>) of std_logic_vector(kInSize-1 downto 0);
	type InputDataArray_8 is array (natural range  <>) of std_logic_vector(8-1 downto 0);
	--type InputData_SignedArray is array (natural range  <>) of signed(kInSize-1 downto 0);

	--signal for Down Convert
	signal DownCvrt_out_I, DownCvrt_out_Q : InputDataArray(7 downto 0);

	--signal for TR
	signal TR_in_I, TR_in_Q     : InputDataArray_8(7 downto 0);
	signal TR_in_I_s, TR_in_Q_s : InputDataArray_8(7 downto 0);
	signal TR_in_I_p4, TR_in_Q_p4 : InputDataArray_8(3 downto 0);
	signal TR_out_I, TR_out_Q : InputDataArray_8(3 downto 0);
	signal TR_out_enable , TR_in_enable : std_logic;


begin

	DownConvert_inst : DownConvert
    generic map(
      kInSize   => 8,
      kOutSize  => 8,
      kNCOSize	 => 16
     )
    port map(
      aReset            => aReset,
      clk               => clk_100,
      AD_sample0        => AD_d0,
	  AD_sample1        => AD_d1,
	  AD_sample2        => AD_d2,
	  AD_sample3        => AD_d3,
	  AD_sample4        => AD_d4,
	  AD_sample5        => AD_d5,
	  AD_sample6        => AD_d6,
	  AD_sample7        => AD_d7,

	  InPhase0			=> DownCvrt_out_I(0),
	  InPhase1			=> DownCvrt_out_I(1),
	  InPhase2			=> DownCvrt_out_I(2),
	  InPhase3			=> DownCvrt_out_I(3),
	  InPhase4			=> DownCvrt_out_I(4),
	  InPhase5			=> DownCvrt_out_I(5),
	  InPhase6			=> DownCvrt_out_I(6),
	  InPhase7			=> DownCvrt_out_I(7),

	  QuadPhase0		=> DownCvrt_out_Q(0),
	  QuadPhase1		=> DownCvrt_out_Q(1),
	  QuadPhase2		=> DownCvrt_out_Q(2),
	  QuadPhase3		=> DownCvrt_out_Q(3),
	  QuadPhase4		=> DownCvrt_out_Q(4),
	  QuadPhase5		=> DownCvrt_out_Q(5),
	  QuadPhase6		=> DownCvrt_out_Q(6),
	  QuadPhase7		=> DownCvrt_out_Q(7)
     );



	----  Decimate Filter  and   Matching Filter
	LPF_P8_D2_instI :	LPF_P8_D2
	 generic map(
		kInSize  => 8,
		kOutSize => 8)
	port map(
		aReset	=> aReset,
		Clk		=> clk_100,
		cDin0	=> DownCvrt_out_I(0),
		cDin1	=> DownCvrt_out_I(1),
		cDin2	=> DownCvrt_out_I(2),
		cDin3	=> DownCvrt_out_I(3),
		cDin4	=> DownCvrt_out_I(4),
		cDin5	=> DownCvrt_out_I(5),
		cDin6	=> DownCvrt_out_I(6),
		cDin7	=> DownCvrt_out_I(7),
		cDout0	=> TR_in_I_p4(0),
		cDout1	=> TR_in_I_p4(1),
		cDout2	=> TR_in_I_p4(2),
		cDout3	=> TR_in_I_p4(3)
		);


	LPF_P8_D2_instQ :	LPF_P8_D2
	 generic map(
		kInSize  => 8,
		kOutSize => 8)
	port map(
		aReset	=> aReset,
		Clk		=> clk_100,
		cDin0	=> DownCvrt_out_Q(0),
		cDin1	=> DownCvrt_out_Q(1),
		cDin2	=> DownCvrt_out_Q(2),
		cDin3	=> DownCvrt_out_Q(3),
		cDin4	=> DownCvrt_out_Q(4),
		cDin5	=> DownCvrt_out_Q(5),
		cDin6	=> DownCvrt_out_Q(6),
		cDin7	=> DownCvrt_out_Q(7),
		cDout0	=> TR_in_Q_p4(0),
		cDout1	=> TR_in_Q_p4(1),
		cDout2	=> TR_in_Q_p4(2),
		cDout3	=> TR_in_Q_p4(3)
		);

	P4toP8_8_instI :	P4toP8_8
	 generic map(
		kDataWidth  => 8 )
	port map(
		aReset		=> aReset,
		clk_in		=> clk_100,
		clk_out		=> pclk_I,
		data_in1		=> TR_in_I_p4(0),
		data_in2		=> TR_in_I_p4(1),
		data_in3		=> TR_in_I_p4(2),
		data_in4		=> TR_in_I_p4(3),
		valid_in	=> '1',

		data_out1		=> TR_in_I_s(0),
		data_out2		=> TR_in_I_s(1),
		data_out3		=> TR_in_I_s(2),
		data_out4		=> TR_in_I_s(3),
		data_out5		=> TR_in_I_s(4),
		data_out6		=> TR_in_I_s(5),
		data_out7		=> TR_in_I_s(6),
		data_out8		=> TR_in_I_s(7),
		valid_out	=> open
		);

	P4toP8_8_instQ :	P4toP8_8
	 generic map(
		kDataWidth  => 8 )
	port map(
		aReset		=> aReset,
		clk_in		=> clk_100,
		clk_out		=> pclk_I,
		data_in1		=> TR_in_Q_p4(0),
		data_in2		=> TR_in_Q_p4(1),
		data_in3		=> TR_in_Q_p4(2),
		data_in4		=> TR_in_Q_p4(3),
		valid_in	=> '1',

		data_out1		=> TR_in_Q_s(0),
		data_out2		=> TR_in_Q_s(1),
		data_out3		=> TR_in_Q_s(2),
		data_out4		=> TR_in_Q_s(3),
		data_out5		=> TR_in_Q_s(4),
		data_out6		=> TR_in_Q_s(5),
		data_out7		=> TR_in_Q_s(6),
		data_out8		=> TR_in_Q_s(7),
		valid_out	=> open
		);

inst_shape_I:	shapingfilter_p8
generic map(
		kInSize  => 8,
		kOutSize => 8)
port map(
		aReset	=> aReset ,
		Clk		=> pclk_I ,
		cDin0	   => TR_in_I_s(0) ,
		cDin1    => TR_in_I_s(1) ,
		cDin2	   => TR_in_I_s(2) ,
		cDin3	   => TR_in_I_s(3) ,
		cDin4	   => TR_in_I_s(4) ,
		cDin5	   => TR_in_I_s(5) ,
		cDin6	   => TR_in_I_s(6) ,
		cDin7	   => TR_in_I_s(7) ,
		cDout0	 => TR_in_I(0)   ,
		cDout1	 => TR_in_I(1)   ,
		cDout2	 => TR_in_I(2)   ,
		cDout3	 => TR_in_I(3)   ,
		cDout4	 => TR_in_I(4)   ,
		cDout5	 => TR_in_I(5)   ,
		cDout6	 => TR_in_I(6)   ,
		cDout7	 => TR_in_I(7)
		);

inst_shape_Q:	shapingfilter_p8
generic map(
		kInSize  => 8,
		kOutSize => 8)
port map(
		aReset	=> aReset ,
		Clk			=> pclk_I ,
		cDin0	   => TR_in_Q_s(0) ,
		cDin1    => TR_in_Q_s(1) ,
		cDin2	   => TR_in_Q_s(2) ,
		cDin3	   => TR_in_Q_s(3) ,
		cDin4	   => TR_in_Q_s(4) ,
		cDin5	   => TR_in_Q_s(5) ,
		cDin6	   => TR_in_Q_s(6) ,
		cDin7	   => TR_in_Q_s(7) ,
		cDout0	 => TR_in_Q(0)   ,
		cDout1	 => TR_in_Q(1)   ,
		cDout2	 => TR_in_Q(2)   ,
		cDout3	 => TR_in_Q(3)   ,
		cDout4	 => TR_in_Q(4)   ,
		cDout5	 => TR_in_Q(5)   ,
		cDout6	 => TR_in_Q(6)   ,
		cDout7	 => TR_in_Q(7)
		);

		RSSI_p4_inst :  RSSI_p4
		  generic map(
		  kInSize => 8,
		  kOutsize => 8
		  )
		  port map(
		  aReset  => aReset ,
		  clk     => pclk_I ,

		  d_in_I0  => TR_in_I(0)   ,
		  d_in_I1  => TR_in_I(1)   ,
		  d_in_I2  => TR_in_I(2)   ,
		  d_in_I3  => TR_in_I(3)   ,
		  d_in_I4  => TR_in_I(4)   ,
		  d_in_I5  => TR_in_I(5)   ,
		  d_in_I6  => TR_in_I(6)   ,
		  d_in_I7  => TR_in_I(7)   ,
		  d_in_Q0  => TR_in_Q(0)   ,
		  d_in_Q1  => TR_in_Q(1)   ,
		  d_in_Q2  => TR_in_Q(2)   ,
		  d_in_Q3  => TR_in_Q(3)   ,
		  d_in_Q4  => TR_in_Q(4)   ,
		  d_in_Q5  => TR_in_Q(5)   ,
		  d_in_Q6  => TR_in_Q(6)   ,
		  d_in_Q7  => TR_in_Q(7)   ,
		  val_in   => '1',

		  rssi_out  => RSSI_out
		  );

--	----------------------Timer recovery with parallel Gardner algorithm-------------------------start
    TimerecoveryP8_v2_inst: TimerecoveryP8_v2
        generic map(
                kDecimateRate   => 13,  -- bit width of Fraction decimate
                kCountWidth     => 4,   -- bit width of the Counter,it is used in Interpolator.(attention: this parameter must be 4 under 8 parallel condition)
                kDelay          => 10,   -- delay of the Interpolate Controller.
                kDataWidth      => 8,
                kErrorWidth     => 16,
                kKpSize         => 3,
                kKiSize         => 3)   -- bit width of the input data.
        port map(
                aReset          => aReset,
                Clk_in          => pclk_I,
                sEnable         => '1', --TR_in_enable,

                sDataInPhase0   => signed(TR_in_I(0)),
                sDataInPhase1   => signed(TR_in_I(1)),
                sDataInPhase2   => signed(TR_in_I(2)),
                sDataInPhase3   => signed(TR_in_I(3)),
                sDataInPhase4   => signed(TR_in_I(4)),
                sDataInPhase5   => signed(TR_in_I(5)),
                sDataInPhase6   => signed(TR_in_I(6)),
                sDataInPhase7   => signed(TR_in_I(7)),

                sDataQuadPhase0   => signed(TR_in_Q(0)),
                sDataQuadPhase1   => signed(TR_in_Q(1)),
                sDataQuadPhase2   => signed(TR_in_Q(2)),
                sDataQuadPhase3   => signed(TR_in_Q(3)),
                sDataQuadPhase4   => signed(TR_in_Q(4)),
                sDataQuadPhase5   => signed(TR_in_Q(5)),
                sDataQuadPhase6   => signed(TR_in_Q(6)),
                sDataQuadPhase7   => signed(TR_in_Q(7)),

                -- recovered symbols
                sInPhaseOut0       => sInPhaseOut0,
                sInPhaseOut1       => sInPhaseOut1,
                sInPhaseOut2       => sInPhaseOut2,
                sInPhaseOut3       => sInPhaseOut3,
                sQuadPhaseOut0     => sQuadPhaseOut0,
                sQuadPhaseOut1     => sQuadPhaseOut1,
                sQuadPhaseOut2     => sQuadPhaseOut2,
                sQuadPhaseOut3     => sQuadPhaseOut3,
                sEnableOut         => sEnableOut
					 );

end rt1;
