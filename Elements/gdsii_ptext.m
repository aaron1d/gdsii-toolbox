function [bl, width] = gdsii_ptext(str, pos, height, layer, ang);
%function [bl, width] = gdsii_ptext(str, pos, height, layer, ang);
%
% gdsii_ptext : draw a text with characters made from boundaries
%               suitable for lithographic reproduction.
%
% str   :  string to be drawn. The string can contain ASCII characters
%          33 to 126 and spaces (ASCII 32). char(127) encodes a lower
%          case Greek mu.
% pos   :  position where the text is drawn in user coordinates
% height:  height of the character box in user coordinates
% layer :  (Optional) layer on which to draw the string. Default is 1.
% ang   :  (Optional) rotate text by angle 'ang' around the bottom
%          left corner of the textbox. 'ang' must be in radians.
%
% bl    :  a compound gds_element object (boundaries)
% width :  (Optional) Width of the string in the same units as height
%
% ASCII table
%
% Char  Dec  Oct  Hex | Char  Dec  Oct  Hex | Char Dec  Oct   Hex
%----------------------------------------------------------------
% (sp)   32 0040 0x20 | @      64 0100 0x40 | `      96 0140 0x60
% !      33 0041 0x21 | A      65 0101 0x41 | a      97 0141 0x61
% "      34 0042 0x22 | B      66 0102 0x42 | b      98 0142 0x62
% #      35 0043 0x23 | C      67 0103 0x43 | c      99 0143 0x63
% $      36 0044 0x24 | D      68 0104 0x44 | d     100 0144 0x64
% %      37 0045 0x25 | E      69 0105 0x45 | e     101 0145 0x65
% &      38 0046 0x26 | F      70 0106 0x46 | f     102 0146 0x66
% '      39 0047 0x27 | G      71 0107 0x47 | g     103 0147 0x67
% (      40 0050 0x28 | H      72 0110 0x48 | h     104 0150 0x68
% )      41 0051 0x29 | I      73 0111 0x49 | i     105 0151 0x69
% *      42 0052 0x2a | J      74 0112 0x4a | j     106 0152 0x6a
% +      43 0053 0x2b | K      75 0113 0x4b | k     107 0153 0x6b
% ,      44 0054 0x2c | L      76 0114 0x4c | l     108 0154 0x6c
% -      45 0055 0x2d | M      77 0115 0x4d | m     109 0155 0x6d
% .      46 0056 0x2e | N      78 0116 0x4e | n     110 0156 0x6e
% /      47 0057 0x2f | O      79 0117 0x4f | o     111 0157 0x6f
% 0      48 0060 0x30 | P      80 0120 0x50 | p     112 0160 0x70
% 1      49 0061 0x31 | Q      81 0121 0x51 | q     113 0161 0x71
% 2      50 0062 0x32 | R      82 0122 0x52 | r     114 0162 0x72
% 3      51 0063 0x33 | S      83 0123 0x53 | s     115 0163 0x73
% 4      52 0064 0x34 | T      84 0124 0x54 | t     116 0164 0x74
% 5      53 0065 0x35 | U      85 0125 0x55 | u     117 0165 0x75
% 6      54 0066 0x36 | V      86 0126 0x56 | v     118 0166 0x76
% 7      55 0067 0x37 | W      87 0127 0x57 | w     119 0167 0x77
% 8      56 0070 0x38 | X      88 0130 0x58 | x     120 0170 0x78
% 9      57 0071 0x39 | Y      89 0131 0x59 | y     121 0171 0x79
% :      58 0072 0x3a | Z      90 0132 0x5a | z     122 0172 0x7a
% ;      59 0073 0x3b | [      91 0133 0x5b | {     123 0173 0x7b
% <      60 0074 0x3c | \      92 0134 0x5c | |     124 0174 0x7c
% =      61 0075 0x3d | ]      93 0135 0x5d | }     125 0175 0x7d
% >      62 0076 0x3e | ^      94 0136 0x5e | ~     126 0176 0x7e
% ?      63 0077 0x3f | _      95 0137 0x5f | \mu   127 0177 0x7f (greek mu)

% initial version: Ulf Griesmann, January 2008
% optionally return boundaries instead of writing to file: ug, Jan 2011
% return a gds_element object. ug, july 2011
% upgraded to DEPLOF font by David Elata, ug, december 2011
% added missing characters, ug, Jan 2012
% added the Greek mu, UG, July 2014

persistent gdsii_fst;   % symbol table

if nargin < 5, ang = []; end;
if nargin < 4, layer = []; end;
if nargin < 3, 
   error('missing argument(s)');
end

if isempty(layer), layer = 1; end;
if isempty(ang), ang = 0; end;

spac = 0.15;                 % symbol spacing

if isempty(gdsii_fst)        % generate symbols at the first call
   gdsii_fst = gen_glyph_table;
end

% draw the string
cpos = pos;                  % current position
lwid = 0;                    % width of the string
vdir = [cos(ang), sin(ang)]; % direction of text
lbl = {};                    % local list of boundaries

for k=1:length(str)
  
  nc = double(str(k));       % character ASCII index
  
  if nc > 32 && nc <= 127
     if iscell(gdsii_fst(nc).gly)
        for m = 1:length(gdsii_fst(nc).gly)
           xy = gdsii_fst(nc).gly{m};
           glypt = height * poly_rotz(xy, ang) + ...
                   repmat(cpos,length(xy),1);
           lbl{end+1} = glypt;% add to list of boundaries
        end
     else
        glypt = height * poly_rotz(gdsii_fst(nc).gly, ang) + ...
                repmat(cpos,length(gdsii_fst(nc).gly),1);
        lbl{end+1} = glypt;     % add to list of boundaries
     end
     
     % advance position
     dpos = vdir * height * (gdsii_fst(nc).wid + gdsii_fst(nc).ind + spac);
     lwid = lwid + norm(dpos , 2);
     cpos = cpos + dpos;
  
  elseif nc == 32            % it's a space
     % advance position by 80% of height
     dpos = vdir * height * 0.8;
     cpos = cpos + dpos;
     lwid = lwid + norm(dpos , 2);
     continue
  
  else
     error(sprintf('character >>> %c <<< is not supported.', str(k)));
  end
end

% return the data
bl = gds_element('boundary', 'xy',lbl, 'layer',layer);
width = lwid;

return


% --------------------------------
%
function [L] = gen_glyph_table;
%
% Defines the glyphs for the font. The glyphs are from the
% True Type Font DEPLOF by David Elata, MEMS Lab, Technion, Haifa,
% Israel, and are used with permission. Some of the characters were
% slightly modified to improve aesthetics (e.g. 'a' no longer wears
% a baseball cap backwards, comma and semi-colon curve the right way, 
% etc.). Missing characters were added.
%
% Every symbol consists of a glyph, a n x 2 matrix of points, (or a
% cell array of nx2 matrices for glyphs that require more than one
% polygon) and width and indentation needed for the symbol. 
% The height of all symbols is scaled to 1. 
%
% Indices:
% ASCII characters from 32 to 126 and 127 for Greek mu
%
% Returns:
% L{k}.gly : n x 2 matrix of points (one per row) which describe
%            a glyph or a cell array of n x 2 matrices when the
%            glyph consists of more than one polygon
% L{k}.wid : width of symbol when height is normalized to 1
% L{k}.ind : indentation of symbol in character box
%
% Ulf Griesmann, December 24-26, 2007
% updated to DEPLOF font, Ulf Griesmann, December 2011
% added missing characters, Ulf Griesmann, January 2012
% added Greek mu as char(127), Ulf Griesmann, July 2014

% glyph list (last one first to pre-allocate array)
L(127).gly = 0.001*[300,700;300,300;400,200;500,200;600,300;600,700;800,700;800,0;600,0;600,100;500,0;400,0;300,100;300,-300;100,-300;100,700;300,700];
L(127).wid = 0.70; L(127).ind = 0.10; % Greek mu
%
L(33).gly = {0.001*[100,-100;100,100;300,100;300,-100;100,-100],0.001*[100,250;100,1100;300,1100;300,250;100,250]};
L(34).gly = {0.001*[300,800;300,1200;500,1200;500,1000;300,800],0.001*[600,800;600,1200;800,1200;800,1000;600,800]};
L(35).gly = {0.001*[150,0;170,200;50,200;50,400;190,400;210,600;100,600;100,800;230,800;250,1000;450,1000;390,400;530,400;510,200;370,200;350,0;150,0],0.001*[550,0;610,600;470,600;490,800;630,800;650,1000;850,1000;830,800;950,800;950,600;810,600;790,400;900,400;900,200;770,200;750,0;550,0]};
L(36).gly = 0.001*[400,1000;400,1200;600,1200;600,1000;800,1000;900,900;900,800;300,800;300,600;400,600;400,700;600,700;600,600;800,600;900,500;900,100;800,0;600,0;600,-200;400,-200;400,0;200,0;100,100;100,200;700,200;700,400;600,400;600,300;400,300;400,400;200,400;100,500;100,900;200,1000;400,1000]; 
L(37).gly = {0.001*[100,100;800,1000;900,900;200,0;100,100],0.001*[100,900;400,900;400,650;350,600;200,600;300,700;300,800;200,800;200,700;100,600;100,900],0.001*[650,400;800,400;700,300;700,200;800,200;800,300;900,400;900,100;600,100;600,350;650,400]};
L(38).gly = {0.001*[700,0;100,600;100,800;200,900;400,900;500,800;500,800;500,600;450,550;350,650;400,700;300,800;200,700;600,300;700,400;800,300;700,200;900,0;700,0],0.001*[550,50;500,0;100,0;0,100;0,300;100,400;150,450;250,350;100,200;100,150;150,100;400,100;450,150;550,50]}; 
L(39).gly = 0.001*[300,800;300,1200;500,1200;500,1000;300,800];
L(40).gly = 0.001*[100,500;125,700;175,900;250,1100;450,1100;375,900;325,700;300,500;325,300;375,100;450,-100;250,-100;175,100;125,300;100,500];
L(41).gly = 0.001*[100,1100;300,1100;375,900;425,700;450,500;425,300;375,100;300,-100;100,-100;175,100;225,300;250,500;225,700;175,900;100,1100];
L(42).gly = {0.001*[450,750;450,1000;550,1000;550,750;800,750;800,650;550,650;550,400;450,400;450,650;200,650;200,750;450,750],0.001*[350,850;250,850;200,900;200,1000;300,1000;350,950;350,850],0.001*[650,850;650,950;700,1000;800,1000;800,900;750,850;650,850],0.001*[650,550;750,550;800,500;800,400;700,400;650,450;650,550],0.001*[350,550;350,450;300,400;200,400;200,500;250,550;350,550]};
% +
L(43).gly = 0.001*[400,600;400,900;600,900;600,600;900,600;900,400;600,400;600,100;400,100;400,400;100,400;100,600;400,600];
L(44).gly = 0.001*[300,200;300,0;100,-200;100,200;300,200];
L(45).gly = 0.001*[900,550;900,350;100,350;100,550;900,550];
L(46).gly = 0.001*[300,200;300,0;100,0;100,200;300,200];
L(47).gly = 0.001*[500,1200;300,-200;100,-200;300,1200;500,1200];
% 0
L(48).gly = {0.001*[400,800;300,700;300,300;400,200;350,0;300,0;100,200;100,800;300,1000;530,1000;480,800;400,800],0.001*[600,200;700,300;700,700;600,800;650,1000;700,1000;900,800;900,200;700,0;470,0;520,200;600,200]};
L(49).gly = 0.001*[200,600;100,600;100,800;300,1000;400,1000;400,200;500,200;500,0;100,0;100,200;200,200;200,600;200,600];
L(50).gly = 0.001*[100,900;200,1000;700,1000;800,900;800,600;400,200;800,200;800,0;100,0;100,200;600,700;600,800;300,800;300,700;100,700;100,900];
L(51).gly = 0.001*[600,1000;800,800;800,600;700,500;800,400;800,200;600,0;300,0;100,200;100,300;300,300;400,200;500,200;600,300;500,400;500,600;600,700;500,800;400,800;300,700;100,700;100,800;300,1000;600,1000];
L(52).gly = 0.001*[800,500;800,300;700,300;700,0;500,0;500,300;100,300;100,1000;300,1000;300,500;500,500;500,1000;700,1000;700,500;800,500];
L(53).gly = 0.001*[800,800;300,800;300,600;700,600;800,500;800,100;700,0;200,0;100,100;100,300;300,300;300,200;600,200;600,400;200,400;100,500;100,1000;800,1000;800,800];
L(54).gly = 0.001*[800,700;600,700;600,800;300,800;300,600;700,600;800,500;800,100;700,0;500,0;500,200;600,200;600,400;300,400;300,200;400,200;400,0;200,0;100,100;100,900;200,1000;700,1000;800,900;800,700];
L(55).gly = 0.001*[560,800;100,800;100,1000;800,1000;600,0;400,0;480,400;520,600;560,800];
L(56).gly = 0.001*[400,800;300,800;300,600;600,600;600,800;500,800;500,1000;700,1000;800,900;800,600;700,500;800,400;800,100;700,0;500,0;500,200;600,200;600,400;300,400;300,200;400,200;400,0;200,0;100,100;100,400;200,500;100,600;100,900;200,1000;400,1000;400,800];
% 9
L(57).gly = 0.001*[100,300;300,300;300,200;600,200;600,400;200,400;100,500;100,900;200,1000;400,1000;400,800;300,800;300,600;600,600;600,800;500,800;500,1000;700,1000;800,900;800,100;700,0;200,0;100,100;100,300];
L(58).gly = {0.001*[300,200;300,0;100,0;100,200;300,200],0.001*[300,600;300,400;100,400;100,600;300,600]};
L(59).gly = {0.001*[300,200;300,0;100,-200;100,200;300,200],0.001*[300,600;300,400;100,400;100,600;300,600]};
L(60).gly = 0.001*[700,900;700,700;400,500;700,300;700,100;100,500;700,900];
L(61).gly = {0.001*[100,400;900,400;900,200;100,200;100,400],0.001*[100,800;900,800;900,600;100,600;100,800]};
L(62).gly = 0.001*[700,500;100,100;100,300;400,500;100,700;100,900;700,500];
L(63).gly = {0.001*[100,1000;200,1100;800,1100;900,1000;900,500;800,400;600,400;600,200;400,200;400,500;500,600;700,600;700,900;300,900;300,800;100,800;100,1000],0.001*[600,50;600,-150;400,-150;400,50;600,50]};
L(64).gly = 0.001*[900,200;900,100;800,0;300,0;100,200;100,800;300,1000;700,1000;900,800;900,500;800,400;450,400;400,450;400,600;450,700;600,700;550,600;550,500;700,500;700,700;600,800;400,800;300,700;300,300;400,200;900,200];
% A
L(65).gly = 0.001*[100,800;300,1000;601,1000;800,800;800,0;601,0;601,200;500,200;500,400;601,400;601,700;500,800;400,800;300,700;300,400;400,400;400,200;300,200;300,0;99,0;100,800];
L(66).gly = 0.001*[600,1000;800,800;800,600;700,500;800,400;800,200;600,0;100,0;100,400;300,400;300,200;500,200;600,300;500,400;420,400;420,600;500,600;600,700;500,800;300,800;300,600;100,600;100,1000;600,1000];
L(67).gly = 0.001*[300,0;100,200;100,800;300,1000;600,1000;800,800;800,600;600,600;600,700;500,800;400,800;300,700;300,300;400,200;500,200;600,300;600,400;800,400;800,200;600,0;300,0];
L(68).gly = 0.001*[100,0;100,400;300,400;300,200;500,200;600,300;600,700;500,800;300,800;300,600;100,600;100,1000;600,1000;800,800;800,200;600,0;100,0];
L(69).gly = 0.001*[700,1000;700,800;300,800;300,600;500,600;500,400;300,400;300,200;700,200;700,0;100,0;100,1000;700,1000];
L(70).gly = 0.001*[100,0;100,1000;700,1000;700,800;300,800;300,600;500,600;500,400;300,400;300,0;100,0];
L(71).gly = 0.001*[300,0;100,200;100,800;300,1000;600,1000;800,800;800,700;600,700;500,800;400,800;300,700;300,300;400,200;600,200;600,300;500,300;500,500;800,500;800,100;700,0;300,0];
L(72).gly = 0.001*[100,1000;300,1000;300,600;600,600;600,1000;800,1000;800,0;600,0;600,400;300,400;300,0;100,0;100,1000];
L(73).gly = 0.001*[100,0;100,200;300,200;300,800;100,800;100,1000;700,1000;700,800;500,800;500,200;700,200;700,0;100,0];
L(74).gly = 0.001*[300,200;500,200;500,1000;700,1000;700,100;600,0;200,0;100,100;100,300;300,300;300,200];
L(75).gly = 0.001*[100,1000;300,1000;300,600;600,1000;800,1000;800,900;500,500;800,100;800,0;600,0;300,400;300,0;100,0;100,1000];
L(76).gly = 0.001*[100,1000;300,1000;300,200;800,200;800,0;100,0;100,1000];
L(77).gly = 0.001*[100,1000;300,1000;500,700;700,1000;900,1000;900,0;700,0;700,600;500,300;300,600;300,0;100,0;100,1000];
L(78).gly = 0.001*[100,1000;300,1000;700,400;700,1000;900,1000;900,0;700,0;300,600;300,0;100,0;100,1000];
L(79).gly = 0.001*[100,800;300,1000;430,1000;430,800;400,800;300,700;300,300;400,200;600,200;700,300;700,700;600,800;570,800;570,1000;700,1000;900,800;900,200;700,0;300,0;100,200;100,800];
L(80).gly = 0.001*[100,1000;700,1000;900,800;900,600;700,400;500,400;500,600;600,600;700,700;600,800;300,800;300,0;100,0;100,1000];
L(81).gly = 0.001*[100,800;300,1000;700,1000;900,800;900,200;800,100;900,0;600,0;600,400;700,400;700,700;600,800;400,800;300,700;300,300;400,200;400,0;300,0;100,200;100,800];
L(82).gly = 0.001*[100,1000;700,1000;900,800;900,600;700,400;900,200;900,0;700,0;700,100;500,300;500,600;600,600;700,700;600,800;300,800;300,0;100,0;100,1000];
L(83).gly = 0.001*[900,800;300,800;300,600;800,600;900,500;900,100;800,0;200,0;100,100;100,200;700,200;700,400;200,400;100,500;100,900;200,1000;800,1000;900,900;900,800];
L(84).gly = 0.001*[900,1000;900,800;600,800;600,0;400,0;400,800;100,800;100,1000;900,1000];
L(85).gly = 0.001*[300,1000;300,300;400,200;500,200;600,300;600,1000;800,1000;800,200;600,0;300,0;100,200;100,1000;300,1000];
L(86).gly = 0.001*[300,1000;500,400;700,1000;900,1000;600,0;400,0;100,1000;300,1000];
L(87).gly = 0.001*[100,1000;300,1000;300,400;500,700;700,400;700,1000;900,1000;900,0;700,0;500,300;300,0;100,0;100,1000];
L(88).gly = 0.001*[367,500;100,900;100,1000;300,1000;500,700;700,1000;900,1000;900,900;633,500;900,100;900,0;700,0;500,300;300,0;100,0;100,100;367,500];
L(89).gly = 0.001*[600,450;600,0;400,0;400,450;100,900;100,1000;300,1000;500,700;700,1000;900,1000;900,900;600,450];
% Z
L(90).gly = 0.001*[100,1000;900,1000;900,700;300,200;900,200;900,0;100,0;100,300;700,800;100,800;100,1000];
L(91).gly = 0.001*[400,1200;400,1000;300,1000;300,0;400,0;400,-200;100,-200;100,1200;400,1200];
L(92).gly = 0.001*[300,1200;500,-200;300,-200;100,1200;300,1200];
L(93).gly = 0.001*[400,1200;400,-200;100,-200;100,0;200,0;200,1000;100,1000;100,1200;400,1200];
L(94).gly = 0.001*[0,500;400,900;800,500;600,500;400,700;200,500;0,500];
L(95).gly = 0.001*[100,200;900,200;900,0;100,0;100,200];
L(96).gly = 0.001*[300,1000;300,1200;500,1200;500,800;300,1000];
% a
L(97).gly = 0.001*[800,0;300,0;100,200;100,500;334,700;600,700;600,775;800,775;800,400;600,400;600,500;400,500;300,400;300,300;400,200;600,200;600,300;800,300;800,0];
L(98).gly = 0.001*[100,300;300,300;300,200;500,200;600,300;600,400;500,500;300,500;300,400;100,400;100,1000;300,1000;300,700;600,700;800,500;800,200;600,0;100,0;100,300];
L(99).gly = 0.001*[800,200;600,0;300,0;100,200;100,500;300,700;600,700;800,500;800,400;600,400;500,500;400,500;300,400;300,300;400,200;500,200;600,300;800,300;800,200];
L(100).gly = 0.001*[800,0;300,0;100,200;100,500;300,700;600,700;600,1000;800,1000;800,400;600,400;600,500;400,500;300,400;300,300;400,200;600,200;600,300;800,300;800,0];
L(101).gly = 0.001*[200,0;100,100;100,700;200,800;700,800;800,700;800,400;700,300;440,300;440,500;600,500;600,600;300,600;300,200;800,200;800,100;700,0;200,0];
L(102).gly = 0.001*[600,800;300,800;300,600;500,600;500,400;300,400;300,0;100,0;100,900;200,1000;600,1000;600,800];
L(103).gly = 0.001*[800,400;600,400;600,500;400,500;300,400;300,300;400,200;600,200;600,300;800,300;800,-200;700,-300;300,-300;200,-200;100,-100;600,-100;600,0;334,0;100,200;100,500;300,700;800,700;800,400];
L(104).gly = 0.001*[600,0;600,400;500,500;400,500;300,400;300,0;100,0;100,1100;300,1100;300,600;400,700;600,700;800,500;800,0;600,0];
L(105).gly = {0.001*[100,0;100,600;300,600;300,0;100,0],0.001*[300,1000;300,800;100,800;100,1000;300,1000]};
L(106).gly = {0.001*[100,-100;100,0;300,0;300,600;500,600;500,-100;400,-200;200,-200;100,-100],0.001*[500,1000;500,800;300,800;300,1000;500,1000]};
L(107).gly = 0.001*[300,500;600,700;800,700;800,600;500,400;800,100;800,0;600,0;300,300;300,0;100,0;100,1100;300,1100;300,500];
L(108).gly = 0.001*[500,0;200,0;100,100;100,1000;300,1000;300,200;500,200;500,0];
L(109).gly = 0.001*[500,400;400,500;300,400;300,0;100,0;100,700;300,700;300,600;400,700;500,700;600,600;700,700;900,700;1100,500;1100,0;900,0;900,400;800,500;700,400;700,0;500,0;500,400];
L(110).gly = 0.001*[600,0;600,400;500,500;400,500;300,400;300,0;100,0;100,700;300,700;300,600;400,700;600,700;800,500;800,0;600,0];
L(111).gly = 0.001*[600,700;800,500;800,200;600,0;300,0;100,200;100,500;300,700;400,700;400,500;300,400;300,300;400,200;500,200;600,300;600,400;500,500;500,700;600,700];
L(112).gly = 0.001*[100,700;600,700;800,500;800,200;600,0;300,0;300,-300;100,-300;100,300;300,300;300,200;500,200;600,300;600,400;500,500;300,500;300,400;100,400;100,700];
L(113).gly = 0.001*[800,400;600,400;600,500;400,500;300,400;300,300;400,200;600,200;600,300;800,300;800,-300;600,-300;600,0;300,0;100,200;100,500;300,700;800,700;800,400];
L(114).gly = 0.001*[600,400;600,500;400,500;300,400;300,0;100,0;100,700;300,700;300,600;400,700;700,700;800,600;800,400;600,400];
L(115).gly = 0.001*[200,0;100,100;100,200;600,200;600,300;200,300;100,400;100,700;200,800;700,800;800,700;800,600;300,600;300,500;700,500;800,400;800,100;700,0;200,0];
L(116).gly = 0.001*[600,0;400,0;300,100;300,600;100,600;100,800;300,800;300,1000;500,1000;500,800;700,800;700,600;500,600;500,200;600,200;600,0];
L(117).gly = 0.001*[300,700;300,300;400,200;500,200;600,300;600,700;800,700;800,0;600,0;600,100;500,0;300,0;100,200;100,700;300,700];
L(118).gly = 0.001*[300,0;100,700;300,700;400,350;500,700;700,700;500,0;300,0];
L(119).gly = 0.001*[600,350;500,0;300,0;100,700;300,700;400,350;500,700;700,700;800,350;900,700;1100,700;900,0;700,0;600,350];
L(120).gly = 0.001*[308,350;100,600;100,700;300,700;450,520;600,700;800,700;800,600;592,350;800,100;800,0;600,0;450,180;300,0;100,0;100,100;308,350];
L(121).gly = 0.001*[214,-300;300,0;100,700;300,700;400,350;500,700;700,700;500,0;414,-300;214,-300];
%z
L(122).gly = 0.001*[100,500;100,700;700,700;700,500;400,200;700,200;700,0;100,0;100,200;400,500;100,500];
L(123).gly = 0.001*[100,500;200,600;200,1000;400,1200;500,1200;500,1000;400,1000;400,600;300,500;400,400;400,0;500,0;500,-200;400,-200;200,0;200,400;100,500];
L(124).gly = 0.001*[100,-100;100,1100;300,1100;300,-100;100,-100];
L(125).gly = 0.001*[500,500;400,600;400,1000;200,1200;100,1200;100,1000;200,1000;200,600;300,500;200,400;200,0;100,0;100,-200;200,-200;400,0;400,400;500,500];
L(126).gly = 0.001*[100,700;250,800;350,800;650,600;750,600;900,700; 900,500;750,400;650,400;350,600;250,600;100,500;100,700];

% glyph widths and indents
L(33).wid = 0.4;   L(33).ind = 0.10; % !
L(34).wid = 0.50;  L(34).ind = 0.20; % "
L(35).wid = 0.80;  L(35).ind = 0.10; % #
L(36).wid = 0.80;  L(36).ind = 0.10; % $
L(37).wid = 0.80;  L(37).ind = 0.10; % %
L(38).wid = 0.90;  L(38).ind = 0.00; % &
L(39).wid = 0.20;  L(39).ind = 0.30; % '
L(40).wid = 0.45;  L(40).ind = 0.10; % (
L(41).wid = 0.45;  L(41).ind = 0.10; % )
L(42).wid = 0.60;  L(42).ind = 0.20; % *
L(43).wid = 0.80;  L(43).ind = 0.10;
L(44).wid = 0.20;  L(44).ind = 0.10;
L(45).wid = 0.80;  L(45).ind = 0.10;
L(46).wid = 0.20;  L(46).ind = 0.10;
L(47).wid = 0.40;  L(47).ind = 0.10;
L(48).wid = 0.80;  L(48).ind = 0.10;
L(49).wid = 0.40;  L(49).ind = 0.10;
L(50).wid = 0.70;  L(50).ind = 0.10;
L(51).wid = 0.70;  L(51).ind = 0.10;
L(52).wid = 0.70;  L(52).ind = 0.10;
L(53).wid = 0.70;  L(53).ind = 0.10;
L(54).wid = 0.70;  L(54).ind = 0.10;
L(55).wid = 0.70;  L(55).ind = 0.10;
L(56).wid = 0.70;  L(56).ind = 0.10;
L(57).wid = 0.70;  L(57).ind = 0.10;
L(58).wid = 0.20;  L(58).ind = 0.10;
L(59).wid = 0.20;  L(59).ind = 0.10;
L(60).wid = 0.60;  L(60).ind = 0.10;
L(61).wid = 0.80;  L(61).ind = 0.10;
L(62).wid = 0.60;  L(62).ind = 0.10;
L(63).wid = 0.80;  L(63).ind = 0.10;
L(64).wid = 0.80;  L(64).ind = 0.10;
L(65).wid = 0.70;  L(65).ind = 0.10;
L(66).wid = 0.70;  L(66).ind = 0.10;
L(67).wid = 0.70;  L(67).ind = 0.10;
L(68).wid = 0.70;  L(68).ind = 0.10;
L(69).wid = 0.60;  L(69).ind = 0.10;
L(70).wid = 0.60;  L(70).ind = 0.10;
L(71).wid = 0.70;  L(71).ind = 0.10;
L(72).wid = 0.70;  L(72).ind = 0.10;
L(73).wid = 0.60;  L(73).ind = 0.10;
L(74).wid = 0.60;  L(74).ind = 0.10;
L(75).wid = 0.70;  L(75).ind = 0.10;
L(76).wid = 0.70;  L(76).ind = 0.10;
L(77).wid = 0.80;  L(77).ind = 0.10;
L(78).wid = 0.80;  L(78).ind = 0.10;
L(79).wid = 0.80;  L(79).ind = 0.10;
L(80).wid = 0.80;  L(80).ind = 0.10;
L(81).wid = 0.80;  L(81).ind = 0.10;
L(82).wid = 0.80;  L(82).ind = 0.10;
L(83).wid = 0.80;  L(83).ind = 0.10;
L(84).wid = 0.80;  L(84).ind = 0.10;
L(85).wid = 0.70;  L(85).ind = 0.10;
L(86).wid = 0.80;  L(86).ind = 0.10;
L(87).wid = 0.80;  L(87).ind = 0.10;
L(88).wid = 0.80;  L(88).ind = 0.10;
L(89).wid = 0.80;  L(89).ind = 0.10;
L(90).wid = 0.80;  L(90).ind = 0.10;
L(91).wid = 0.30;  L(91).ind = 0.10;
L(92).wid = 0.40;  L(92).ind = 0.10;
L(93).wid = 0.30;  L(93).ind = 0.10;
L(94).wid = 0.80;  L(94).ind = 0.00;
L(95).wid = 0.80;  L(95).ind = 0.10;
L(96).wid = 0.20;  L(96).ind = 0.30;
L(97).wid = 0.70;  L(97).ind = 0.10;
L(98).wid = 0.70;  L(98).ind = 0.10;
L(99).wid = 0.70;  L(99).ind = 0.10;
L(100).wid = 0.70; L(100).ind = 0.10;
L(101).wid = 0.70; L(101).ind = 0.10;
L(102).wid = 0.50; L(102).ind = 0.10;
L(103).wid = 0.70; L(103).ind = 0.10;
L(104).wid = 0.70; L(104).ind = 0.10;
L(105).wid = 0.20; L(105).ind = 0.10;
L(106).wid = 0.40; L(106).ind = 0.10;
L(107).wid = 0.70; L(107).ind = 0.10;
L(108).wid = 0.40; L(108).ind = 0.10;
L(109).wid = 1.00; L(109).ind = 0.10;
L(110).wid = 0.70; L(110).ind = 0.10;
L(111).wid = 0.70; L(111).ind = 0.10;
L(112).wid = 0.70; L(112).ind = 0.10;
L(113).wid = 0.70; L(113).ind = 0.10;
L(114).wid = 0.70; L(114).ind = 0.10;
L(115).wid = 0.70; L(115).ind = 0.10;
L(116).wid = 0.60; L(116).ind = 0.10;
L(117).wid = 0.70; L(117).ind = 0.10;
L(118).wid = 0.60; L(118).ind = 0.10;
L(119).wid = 1.00; L(119).ind = 0.10;
L(120).wid = 0.70; L(120).ind = 0.10;
L(121).wid = 0.60; L(121).ind = 0.10;
L(122).wid = 0.60; L(122).ind = 0.10;
L(123).wid = 0.50; L(123).ind = 0.10; % {
L(124).wid = 0.40; L(124).ind = 0.10; % |
L(125).wid = 0.50; L(125).ind = 0.10; % }
L(126).wid = 0.80; L(126).ind = 0.10; % ~

return

%
% The following function is copied from the NIST Optics Toolbox
% to make the GDSII toolbox self contained
%

function [mpos] = poly_rotz(mp, ang)
%function [mpos] = poly_rotz(mp, ang)
%
% poly_rotz : transformation of points by rotation around the z-axis
%
% mpos : points to be transformed; one per row
% ang  : angle around z

mpos = zeros(size(mp));
mpos(:,1) = cos(ang)*mp(:,1) - sin(ang)*mp(:,2);
mpos(:,2) = sin(ang)*mp(:,1) + cos(ang)*mp(:,2);
  
return
