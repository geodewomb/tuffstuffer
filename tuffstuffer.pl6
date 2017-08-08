#!usr/local/bin/perl6

my @armor = slurp_items("stuff/armor.txt");
my @melee = slurp_items("stuff/melee.txt");
my @bigweap = slurp_items("stuff/bigweap.txt");
my @mixmis = slurp_items("stuff/mixmis.txt");
my @missle = slurp_items("stuff/missle.txt");
my @supplies = slurp_items("stuff/supplies.txt");
my @transit = slurp_items("stuff/transportation.txt");
my @kits = slurp_items("stuff/kits.txt");
my @override;

my ($class, $gold, $pocket, $heavy);

#ntro();

loop {
  my @menu = "+ Equip me! (e) + Help (h) + Quit (q) +";
  say box(@menu); 
  write("What say you? ");
  my $input = prompt('');
  say '';
  given $input.lc {
    when /exit||quit||^q$/ { exit; }
    when /equip||equip\wme||^e$/ { item_master(); }
    when /help||^h$/ { help_me(); }
    default { write("Eh??? Come again??? \n"); }
  }

}


##### subroutines ##############################################

sub box(@content) {    ### formats content for printing

  my $linelength = 0;
  for @content { $linelength = $_.chars if $_.chars > $linelength; }

  for @content {
    my $dif = $linelength - $_.chars; 
    $_ = "| $_" ~ " " x $dif ~ " |";
  }

  my $border = "+-" ~ "-" x $linelength ~ "-+";
  unshift @content, $border;
  push @content, $border;

  return @content.join("\n");
}

sub get_class {   ### queries class and returns snarky comment

  my token wiz { [[m?\-?u]||w] }

  write("What class are you? ");
  
  loop {
    my $input = prompt(''); say '';

    given $input.lc {

      when /exit||quit||^q$/ { exit; }
      when /^$/ { say "No class selected."; } 
      when /^gm$/ { say "GM mode — you will be shown absolutely everything! MWA HA HA!"; return 'x'; }

      # multi-class

      when ( /fig/ and /mag||wiz/ and /th..f||thi||rog/ ) or
           /^ f\s?<wiz>\s?t || f\s?t\s?<wiz> || t\s?f\s?<wiz> || 
              t\s?<wiz>\s?f || <wiz>\s?t\s?f || <wiz>\s?f\s?t $/ { 
        say "Your class is Fighter/Magic-User/Thief.";
        write("~I want the world! I want the whole world!~\n");
      }
      when ( /fig/ and /mag||wiz/ and /cle||pri/ ) or 
           /^ f\s?<wiz>\s?c || f\s?c\s?<wiz> || c\s?f\s?<wiz> || 
              c\s?<wiz>\s?f || <wiz>\s?c\s?f || <wiz>\s?f\s?c $/ { 
        say "Your class is Fighter/Magic-User/Cleric.";
        write("You will be shown only weapons Clerics can use, you ego-maniac.\n");
        return 'c';
      }
      when ( /fig/ and /mag||wiz/ ) or /^ f\s?<wiz> || <wiz>\s?f $/  { 
        say "Your class is Fighter/Magic-User."; 
        write("And not the other way around.\n") 
      } 
      when ( /fig/ and /th..f||thi||rog/ ) or /^ f\s?t || t\s?f $/ { 
        say "Your class is Fighter/Thief."; 
        write("Because your specialty is identity-theft.\n"); 
      }
      
      # single class

      when /^fig||^f$/ { say "Your class is Fighter."; write("...not a lover.\n") }
      when /^pal||^p$/ { say "Your class is Paladin. "; write("It's pronounced puhLAH-din.\n") }
      when /^ran||^r$/ { say "Your class is Ranger.";  write("Rhymes with danger.\n"); }
      when /^mag||^wiz/ or /^<wiz>$/ { 
        say "Your class is Magic-User."; 
        write ("You will only be shown armor and weapons Magic-Users can magic-use.\n");
        return 'w'; 
      } 
      when /^dru||^d$/ { 
        say "Your class is Druid.";
        write("You will only be shown armor and weapons Druids can use, including top-secret druid options!\n");
        return 'd'; 
      }
      when /th..f||^thi||^rog||^t$/ { 
        say "Your class is Thief.";
        write("You will only be shown armor Thieves can use. Don't try anything, we have CCTV.\n");
        return 't'; 
      }
      when /^cle||^pri||^c$/ { 
        say "Your class is Cleric.";
        write("You will only be shown weapons Clerics can use. Warranties do NOT extend to the afterlife.\n");
        return 'c'; 
      }
      when /^ass||^a$/ { 
        say "Your class is Assassin.";
        write("You will only be shown armor sassy Assassins can use.\n");
        return 'a'; 
      }
      when /^mon||^k$/ { 
        say "Your class is Monk.";
        write("You will only be shown armor Monks can use... which is nothing.\n");
        return 'm'; 
      }
      default { write("Sorry, didn't get that. What class are you? (leave blank to skip) "); next; }
    }
    say '';
    return 'f';
  }
}



sub get_gold {   ### queries gold and optionally rolls for it
  
  my @dice = < 0 ⚀  ⚁  ⚂  ⚃  ⚄  ⚅ >;
  $gold = 0;

  write("How much gold have you? ");

  loop {
    my $input = prompt(''); say '';

    given $input.lc {
      when /exit||quit||^q$/ { exit; }
      when /^0$/ { 
        write("I can't afford charity cases! Come back after you've done something useful with your life!\n"); 
        last;
      }
      when /^$||roll/ { 
        for 0..2 { sleep 1; my $num = (1..6).roll; $gold += $num * 10; print @dice[$num] ~ " "; } 
        write("You rolled $gold gold.\n"); say ''; last; 
      }
      when /^ \d+ $/ and $input >= 1000 { write("Please use a value under 1000!\n"); }
      when /^ \d+ $/ and 0 < $input < 1000 { $gold = $input; last; } 
      default { write("Sorry we don't use that currency here... How much gold do you have?\n"); }
    }
  }
  return $gold;
}

sub gm_override {   ### allows custom item adding but needs more verification

  my @inputs = @_.split(':');
  if @inputs[1] ~~ /clear/ { 
    say "Clearing all GM override items."; 
    for @override { $pocket += $_<price>; $heavy -= $_<weight>; }
    @override = ();
    return;
  }
  unless @inputs.elems == 4 { say "GM override requires :[name]:[price]:[weight]."; return; }
  my %item = code => "gm{@override.elems}",
             name => @inputs[1],
             price => @inputs[2],
             weight => @inputs[3],
             note => "GM override item",
             quantity => 1;
  unless $pocket >= %item<price> { say "Item is too expensive."; return; }

  $heavy += %item<weight>;
  $pocket -= %item<price>;
  push @override, %item;
  say "added item %item<name>, %item<price>g, %item<weight>lbs.";
}


sub goodbye {   ### say a random goodbye

  say '';
  my $goodbye = (0..16).pick;
  given $goodbye {
    when 0  { write("All sales final! Returns are for store credit only!") }
    when 1  { write("Don't blame me if you get eaten by trolls...") }
    when 2  { write("You remind me of my sweet love when they were off adventuring. *sniff* Take care now!") }
    when 3  { write_words("COME BACK SOON FOR MORE TOUGH DEALS!!!") }
    when 4  { write("Prices are worse further down the road. Buy now!") }
    when 5  { write("Our weapons come with complimentary "); write_words("TOUGH STUFF"); write("decals!") }
    when 6  { write_words("TOUGH STUFF OUTFITTERS"); write("is not liable for death or dismemberment resulting from the use of our wares.") }
    when 7  { write("Fearsome foe you are! Eh??? Smile more, honey!") }
    when 8  { write_words("IN TOUGH TIMES GET TOUGH STUFF!") }
    when 9  { write("I hope you know what you're doing...") }
    when 10 { write("Don't came back in a coffin!") }
    when 11 { write("Ugh, why do you brutes always smell so funky?") }
    when 12 { write_words("INSTEAD OF CUSTOMERS,"); write_words("WE HAVE TOUGH-STOMERS!") }
    when 13 { write("Have fun storming the castle!") }
    when 14 { write("Nice knowin' ya!") }
    when 15 { write("What did the club say to the daggar? "); write_words(". . . Lookin' sharp!") }
    when 16 { write('Be sure to check out our "battle-proven" bargain rack!') }
  }
  say "\n";
}

sub help_me {   ### help text
  
  say '';
  say qq:to/END/;
This program is for tracking item purchases.

Each item can be added or removed from your list using + (add) or - (remove), an optional number, 
and the three letter code associated with the item. [ +tor ] adds 1 torch, [ +5tor ] adds 5 torches.

Multiple items can be processed at once separated by a space. [ '+hmr +shi -5tor' ]

Upon initializing, you can either state a custom gold amount or the program will roll 3d6 to
generate the standard starting gold amount. Type [ roll ] or leave blank on query)

You can also give the program your class to view only items usable by that class.
(to skip, leave blank on query)

Be sure to press (q) when you're done for an easy-to-read
yet detailed summary of your purchases!

GM overrides can add custom items. [ gm:Item Name, Spaces OK:n:n ] where n:n is gold:weight ]. 
[ gm:clear ] removes all GM override items. 

Typing gm as your class will allow the listing every single item including hidden druid and kit entries.

END
       
}

sub intro {   ### dramatic intro

  write("\nWelcome to "); 
  write_words("TOUGH STUFF OUTFITTERS.");
  write("\nIt's...... ");
  write_words("TOUGH STUFF TIME!"); say "\n";
}

sub item_add($code) {   ### add an item

  for (@armor,@melee,@bigweap,@mixmis,@missle,@supplies,@transit) {
    for $_ -> $entry {
      if $entry<code> ~~ $code {
        unless $pocket >= $entry<price> { say "You can't afford that $entry<name>."; return; } 
        $entry<quantity>++;
        $pocket -= $entry<price>;
        $heavy += $entry<weight>;
        say "added $entry<name>"; 
        return; 
      }
    }
  }
  say "Sorry, [$code] is not an item. Please check the item tables.";
}
       
sub item_lose($code) {   ### remove an item

  for (@armor,@melee,@bigweap,@mixmis,@missle,@supplies,@transit) {
    for $_ -> $entry {
      if $entry<code> ~~ $code { 
        if $entry<quantity> > 0 { 
          $entry<quantity>--;
          $pocket += $entry<price>;
          $heavy -= $entry<weight>; 
          say "removed $entry<name>"; 
          return; 
        }
        else { say "You don't have a $entry<name>!"; return;}
      }
    }
  }
  say "Sorry, [$code] is not an item. Please check the item tables.";
}

sub item_request($in) {   ### parse item add/lose strings

  my @inputs = $in.split(' ');
  for @inputs -> $input {
    if $input ~~ /^ (\+||\-) (\d?\d?) (<:L>**3) $/ {
      my $sig = "$0";
      my $num = "$1";
      my $code = "$2";
      $num = 1 if $num ~~ /^$/;
      if $code.substr(0,1) eq 'k' { say "'k' codes are for kit items. You must add or remove an entire kit."; return; }
      given $sig { 
        when /'+'/ { item_add($code) for ^$num; }
        when /'-'/ { item_lose($code) for ^$num; }
      }
    }
    else { say "Sorry, $input is not a valid format. Please use +[n][***] or -[n][***] where n < 100."; }
  }
}

sub item_master {   ### main working loop
  
  $pocket = get_gold();
  $class = get_class();
  my @menu = "+ List Armor (a) + Weapons (w) + Supplies (s) + Transit (t) + Kits (k) +",
             "+ Add/Remove Items (+/-***) + View Cart (v) + Help! (h) + Checkout (q) +";
  say box(@menu);

  loop {
    say "GOLD LEFT: $pocket / $gold";
    write("What say you? ");
    my $input = prompt(''); say '';

    given $input.lc {
      when /^gm:/ { gm_override($input); }
      when /every||^e$/ { list_all_items(); }
      when /armor||^a$/ { list_armor(); }
      when /weapon||^w$/ { list_weapons(); }
      when /supplies||^s$/ { list_supplies(); }
      when /trans||^t$/ { list_transit(); }
      when /^kit[\+||\-]/ { kit_request($input); say ''; }
      when /kit||^k$/ { list_kits(); }
      when /^\+||^\-/ { item_request($input); say '';} 
      when /view||purchase||^v$/ { print_inv(); }
      when /help||^h$/ { help_me(); }
      when /quit||exit||^q$||^c$/ { print_reciept(); goodbye(); exit;}
      default { write("Can't understand you, speak up!\n\n"); say box(@menu); }
    }
  }
}

sub kit_request($in) {   ### parse kit requests into individual item requests

  if $in ~~ /^kit(\+||\-)(<:L>**3)$/ {
    my $sig = "$0";
    my $code = "$1";

    for @kits -> $k {
      if $k<code> ~~ $code {
        if $sig ~~ /'+'/ {
          unless $pocket >= $k<price> { say "You can't afford the $k<name> kit."; return; }
          for $k<note>.split(' ') { item_add($_); }
          $k<quantity>++;
          $pocket -= $k<price>;
          $heavy += $k<weight>; 
        }
        elsif $sig ~~ /'-'/ { 
          unless $k<quantity> > 0 { say "You don't have the $k<name> kit."; return; }
          for $k<note>.split(' ') { item_lose($_); }
          $k<quantity>--;
          $pocket += $k<price>;
          $heavy -= $k<weight>;
        }
        return;
      } 
    }

    say "[$code] is not a kit. Please check the kit table. (k)"; return;
  }

  say "Kits can be added or removed by typing [ kit+*** ] or [ kit-***]."; 
}


sub list_all_items {
list_armor();
list_weapons();
list_supplies();
list_transit();
}


sub list_armor {
  my @list = "***  NAME                   COST   WEIGHT   AC";
  my @armor_items = pull_items(@armor);
  for @armor_items -> $entry { push @list, $entry; }
  say box(@list);  
}

sub list_kits {
  my @list = "      Pre-made kits for all your needs! Add a kit with [ kit+*** ]."; 
  for @kits {
    my %k = $_;
    %k<name> ~= " ";
    until %k<name>.chars == 18 { %k<name> ~= "-"; }
    %k<price> ~= "g";
    push @list, "%k<code>  {%k<name>}--------------------------------------------- %k<price> / %k<weight> lbs";
    my @third;
    for %k<note>.split(' ') -> $code {
      for (@supplies,@transit) {
        for $_ -> $i { if $i<code> ~~ $code { push @third, $i<name>; } }
      }
    }
    my @first = @third.splice(0, @third/3);
    my @second = @third.splice(0, @third/2);
    until @first.elems >= @third.elems { push @first, @second.shift; }
    until @second.elems == @first.elems { push @second, @third.shift; }
    for 0..^@first.elems -> $x {
      my $line = "     ";
      for @first[$x], @second[$x], @third[$x] {
        next unless $_;
        until $_.chars == 23 { $_ ~= " "; }
        $line ~= " - $_";
      }
      push @list, $line;
    }
  }
  say box(@list); 
}

sub list_supplies {
  
  my @list = "***  NAME                    COST        ***  NAME                    COST";

  my @second;
  for @supplies {
    my @restrict = $_<restrict>.split(' ');
    my $forbidden;
    for @restrict -> $c { if $c eq $class { $forbidden = 1; } }
    next if $forbidden;
    push @second, $_;
  }
  
  my @first = @second.splice(0, Int(@second.elems/2)+1);

  for (0..^@first.elems) -> $x {
    my $line;
    for @first[$x], @second[$x] {
      unless $_ { next; }
      my %i = $_;
      until %i<name>.chars == 23 { %i<name> ~= " "; }
      %i<price> ~= "g";
      until %i<price>.chars == 12 { %i<price> ~= " "; }
      until %i<weight>.chars == 7 { %i<weight> ~= " "; }
      $line ~= "%i<code>  %i<name> %i<price>";
    }
    @list.push($line);
  }
  say box(@list);  
}

sub list_transit {
  my @list = "***  NAME                  COST   ";
  for @transit {
    my %i = $_;
    until %i<name>.chars == 23 { %i<name> ~= " "; }
    %i<price> ~= "g";
    until %i<price>.chars == 12 { %i<price> ~= " "; }
    my $line ~= "%i<code>  %i<name> %i<price>";
    @list.push($line);
  }
  say box(@list);  
}

sub list_weapons {
  my @list = "***  NAME                       COST   WEIGHT   DAMAGE";
  my @title = "Either 1 or 2 handed:",
              "Only 2 handed:",
              "Throwable:",
              "Missile:";
  my $x = 0;
  for (@melee,@bigweap,@mixmis,@missle) {
    my @items = pull_items($_);
    if @items.elems > 0 {
      push @list, @title[$x];
      for @items -> $entry { push @list, $entry; }
      unless $x == 3 { push @list, " "; }
    }
    $x++;
  }
    
  say box(@list);
}

sub print_inv {   ### print short-form inventory

  my @reciept; 
  my @inv;
  for @armor,@melee,@bigweap,@mixmis,@missle,@kits,@supplies,@transit,@override -> $a {
    for (0..^$a.elems) -> $x {
      if $a[$x]<quantity> > 0 { my @line = tally_tiny($a[$x]); for @line { @inv.append($_) } }
    }
    if @inv.elems > 0 { @reciept.append(@inv); }
    @inv = ();
  }
  @reciept.push("TOTAL:  {$gold - $pocket}g  $heavy lbs");
  say box(@reciept);
}

sub print_reciept {   ### print long-form inventory

  my @reciept;
  
  my @inv;
  for @armor { if $_<quantity> > 0 { my $line = tally($_); push @inv, $line; } }
  if @inv.elems > 0 { push @reciept, "ARMOR"; push @reciept, "----------- "; @reciept.append(@inv); }
  @inv = ();
  for @melee { if $_<quantity> > 0 { my $line = tally($_); push @inv, $line; } }
  for @bigweap { if $_<quantity> > 0 { my $line = tally($_); push @inv, $line; } }
  for @mixmis { if $_<quantity> > 0 { my $line = tally($_); push @inv, $line; } }
  for @missle { if $_<quantity> > 0 { my $line = tally($_); push @inv, $line; } }
  if @inv.elems > 0 { push @reciept, " "; push @reciept, "WEAPONS"; push @reciept, "----------- "; @reciept.append(@inv); }
  @inv = ();
  for @kits { 
    if $_<quantity> > 0 { 
      my $line = tally($_);
      my @split = $line.split('lbs');
      @split[*-1] = '-';
      $line = @split.join('lbs  '); 
      push @inv, $line; 
    } 
  }
  if @inv.elems > 0 { push @reciept, " "; push @reciept, "KITS"; push @reciept, "----------- "; @reciept.append(@inv); }
  @inv = ();
  for @supplies { if $_<quantity> > 0 { my $line = tally($_); push @inv, $line; } }
  if @inv.elems > 0 { push @reciept, " "; push @reciept, "SUPPLIES"; push @reciept, "----------- "; @reciept.append(@inv); }
  @inv = ();
  for @transit { if $_<quantity> > 0 { my $line = tally($_); push @inv, $line; } }
  if @inv.elems > 0 { push @reciept, " "; push @reciept, "TRANSIT"; push @reciept, "----------- "; @reciept.append(@inv); }
  @inv = ();
  for @override { if $_<quantity> > 0 { my $line = tally($_); push @inv, $line; } }
  if @inv.elems > 0 { push @reciept, " "; push @reciept, "OTHER"; push @reciept, "----------- "; @reciept.append(@inv); }
  my $amount = $gold - $pocket ~ "g";
  until $amount.chars == 6 { $amount = " " ~ $amount; }
  until $heavy.chars == 4 { $heavy = " " ~ $heavy; }
  push @reciept, " ";
  push @reciept, "TOTAL:                       {$amount} $heavy lbs"; 
 
  my $linelength = 0; 
  for @reciept {
    if $_.chars > $linelength { $linelength = $_.chars; }
  }
  my $header = "~~~~COSTUMER RECIEPT~~~~";
  until (" " ~ $header ~ " ").chars > $linelength { $header = " " ~ $header ~ " "; }
  unshift @reciept, $header;
  say box(@reciept);
}

sub pull_items(@things) {   ### list items off given array and leave out restricted entries
  
  my @pulled;
  for @things {
    my %item = $_;
    my @restrict = %item<restrict>.split(' ');
    my $forbidden = 0;
    for @restrict { $forbidden = 1 if $_ eq $class; }
    next if $forbidden;
    until %item<name>.chars == 20 { %item<name> ~= " "; }
    %item<price> ~= "g";
    until %item<price>.chars == 5 { %item<price> ~= " "; } 
    until %item<weight>.chars == 7 { %item<weight> ~= " "; }
     
    @pulled.push("%item<code>  %item<name> %item<price>  %item<weight>  %item<note>")
  }
  return @pulled;
}

sub slurp_items($path) {   ### load item arrays from external file

  my $file = open "$path", :r;
  my @array;

  for $file.lines {
    my @data = $_.split("\t");
    my $code = shift @data;
    my $price = shift @data;
    my $weight = shift @data;
    my $name = shift @data;
    my $note = shift @data or '';
    my $restrict = shift @data or '';
    my %thing = 'code' => $code,
                'name' => $name,
                'price' => $price,
                'weight' => $weight,
                'note' => $note,
                'restrict' => $restrict,
                'quantity' => 0;
    @array.push(%thing);
  }
  return @array; 
}

sub tally(%i) {   ### pull info out of array and format for listing in the reciept
  
  my $gold_total = %i<price> * %i<quantity> ~ "g";
  until $gold_total.chars >= 5 { $gold_total = " " ~ $gold_total; }  
  my $weight_total = %i<weight> * %i<quantity> ~ " lbs";
  until $weight_total.chars >= 8 { $weight_total = " " ~ $weight_total; }
  my $name = %i<name>;
  until $name.chars >= 23 { $name ~= " "; }
  my $quant = "(%i<quantity>)";
  until $quant.chars >= 5 {$quant ~= " "; }
  return "$name $quant {$gold_total} $weight_total  %i<note>"; 
}

sub tally_tiny(%i) {   ### pull some info out of array for listing in inventory
  
  %i<price> ~= "g";
  until %i<price>.chars >= 5 { %i<price> ~= " "; }  
  %i<weight> ~= " lbs";
  until %i<weight>.chars >= 8 { %i<weight> ~= " "; }
  until %i<name>.chars >= 23 { %i<name> ~= " "; }
  my @line; 
  for 0^..%i<quantity> { @line.push("%i<name> %i<price> %i<weight>"); }
  return @line;
}

sub write($string) {   ### type text character by character
  
  sleep .5;
  my @chars = $string.split('');
  for @chars { print $_; sleep .05; }
}
  
sub write_words($string) {   ### type text word by word

  sleep .5;
  my @words = $string.split(' ');
  for @words { print $_ ~ ' '; sleep .5; }
}
