Program VSPEED;
uses crt,misc,tptimer;

const
 vseg   : word   = $0A000;
 title  : string = 'VGA Speed Test v. 1.0 (c) 2002 by Jan Knipperts';

var
 start,stop,
 fcnt,fcntw,pcnt,pcntb,daccnt : Longint;
 retrace                      : real;
 x,y,maxX,maxY,mode           : word;
 f                            : text;
 k                            : char;

Procedure SetDAC(index,R,G,B:Byte);
assembler;
{ Change the palette}
asm
  mov dx,3c8h
  mov al,[index]
  out dx,al
  inc dx
  mov al,[r]
  out dx,al
  mov al,[g]
  out dx,al
  mov al,[b]
  out dx,al
end;


Procedure Vretrace;
{wait for complete vertical retrace }
assembler;
asm
  mov dx,3dah
 @vert1:
  in al,dx
  test al,8
  jz @vert1
 @vert2:
  in al,dx
  test al,8
  jnz @vert2
end;




Procedure BiosPixel(x,y : word; c : byte);
assembler;
asm
 mov ah,0Ch
 mov al,c
 xor bh,bh
 mov cx,x
 mov dx,y
 int 10h
end;

Procedure PutPixel(x,y:word; c:byte);
{Puts a pixel}
assembler;
asm
  mov es,vseg
  mov ax,[y]
  shl ax,6
  mov di,ax
  shl ax,2
  add di,ax
  add di,[x]
  mov al,[c]
  stosb
end;


Procedure Fillb(c : byte);
{Fills video segment bytewise with value "c"}
assembler;
asm
   mov ax, vseg
   mov es, ax
   xor ax, ax
   mov al, c
   xor di, di
   mov cx,$FFFF
@Loop:
   stosb
   dec cx
jnz @Loop
   mov es:[di],al
end;

Procedure Fillw(c : byte);
{Fills video segment wordwise with value "c"}
assembler;
asm
   mov ax, vseg
   mov es, ax
   mov al, c
   mov ah, c
   xor di, di
   mov cx, 32762
@Loop:
   stosw
   dec cx
jnz @Loop
   mov es:[di],al
end;





begin
 asm
  mov ax,03h
  int 10h
 end;
 textbackground(1);
 textcolor(14);
 gotoxy(1,1);
 insline;
 gotoxy(40-(length(title) div 2),1);
 write(title);
 textbackground(0);
 textcolor(7);
 gotoxy(1,3);
 writeln('Press any Key to start the benchmark of your videocard....');
 while keypressed do readkey;
 repeat until keypressed;
 while keypressed do readkey;

 InitializeTimer;
 mode := $13;

 if mode = $13 then
 begin
  maxX := 320;
  maxY := 200;
 end;

 if mode = $10 then
 begin
  maxX := 640;
  maxY := 480;
 end;

 asm
 mov ax,mode
 int 10h
 end;
 fcnt := 0;
 start := ReadTimer;
 repeat;
  Fillb(15);
  inc(fcnt);
  stop := ReadTimer;
 until (ElapsedTime(start,stop)/ 1000) >= 1;
 Fillb(0);
 fcntw := 0;
 start := ReadTimer;
 repeat;
  Fillw(15);
  inc(fcntw);
  stop := ReadTimer;
 until (ElapsedTime(start,stop)/ 1000) >= 1;
 Fillw(0);
 pcnt := 0;
 start := ReadTimer;
 x := 0;
 y := 0;
 repeat;
    PutPixel(x,y,15);
    inc(pcnt);
    inc(x);
    if x > maxX then
    begin
      x := 1;
      inc(y);
      if y > maxY then y := 1;
    end;
    stop := ReadTimer;
 until (ElapsedTime(start,stop)/ 1000) >= 1;

 Fillw(0);
 pcntb := 0;
 start := ReadTimer;
 x := 0;
 y := 0;
 repeat;
    BiosPixel(x,y,15);
    inc(pcntb);
    inc(x);
    if x > maxX then
    begin
      x := 1;
      inc(y);
      if y > maxY then y := 1;
    end;
    stop := ReadTimer;
 until (ElapsedTime(start,stop)/ 1000) >= 1;

 DACcnt := 0;
 start := ReadTimer;
 repeat;
    SetDAC(15,daccnt mod 63,daccnt mod 63,daccnt mod 63);
    inc(daccnt);
    stop := ReadTimer;
 until (ElapsedTime(start,stop)/ 1000) >= 1;

 retrace := 0;
 start := ReadTimer;
 Vretrace;
 stop := ReadTimer;

 retrace := ElapsedTime(start,stop);




 asm
  mov ax,03h
  int 10h
 end;
 textbackground(1);
 textcolor(14);
 gotoxy(1,1);
 insline;
 gotoxy(40-(length(title) div 2),1);
 write(title);
 textbackground(0);
 textcolor(7);
 gotoxy(1,3);
 writeln('Benchmark results for mode 13h (320x200, 256 color)');
 writeln;
 writeln('Color fill speed (bytewise) ',fcnt,' frames per second');
 writeln('8-Bit Throughput = ',(fcnt * $FFFF) div 1024,' KB/s (',(((fcnt * $FFFF) / 1024) / 1024):3:2,' MB/s)');
 writeln('Color fill speed (wordwise) ',fcntw,' frames per second');
 writeln('16-Bit Throughput = ',(fcntw * $FFFF) div 1024,' KB/s (',(((fcntw * $FFFF) / 1024) / 1024):3:2,' MB/s)');
 writeln;
 writeln('Pixel fill speed (direct memory access): ',pcnt,' Pixels per second');
 writeln('Pixel fill speed (via Video BIOS): ',pcntb,' Pixels per second');
 writeln('DAC Speed: ',DACcnt,' colorchanges per second');
 writeln('Complete vertical retrace takes : ',retrace :2:4,' ms (',(retrace / 1000) :2:4,' seconds)');
 writeln;
 writeln('S saves results to RESULT.TXT,  ESC quits to DOS');
 while keypressed do readkey;
 repeat
 k := readkey;
 if upcase(k) = 'S' then
 begin
  assign(f,'RESULTS.TXT');
  rewrite(f);
   writeln(f,title);
   writeln(f);
   writeln(f,'Color fill speed (bytewise) ',fcnt,' frames per second');
   writeln(f,'8-Bit Throughput = ',(fcnt * $FFFF) div 1024,' KB/s (',(((fcnt * $FFFF) / 1024) / 1024):3:2,' MB/s)');
   writeln(f,'Color fill speed (wordwise) ',fcntw,' frames per second');
   writeln(f,'16-Bit Throughput = ',(fcntw * $FFFF) div 1024,' KB/s (',(((fcntw * $FFFF) / 1024) / 1024):3:2,' MB/s)');
   writeln(f);
   writeln(f,'Pixel fill speed (direct memory access): ',pcnt,' Pixels per second');
   writeln(f,'Pixel fill speed (via Video BIOS): ',pcntb,' Pixels per second');
   writeln(f,'DAC Speed: ',DACcnt,' colorchanges per second');
   writeln(f,'Complete vertical retrace takes : ',retrace :3:2,' ms');
   writeln(f);
  close(f);
  writeln('Results saved!');
 end;

 until k = #27;

 clrscr;
 writeln('Thanks for using');
 RestoreTimer;
end.
