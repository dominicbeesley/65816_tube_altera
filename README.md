# 65816_tube_altera
A DE0 mezzanine board for a 65816 BBC Micro Tube, including a simple TUBE ULA using Flancters for clock domain hopping

More details [here](https://stardot.org.uk/forums/viewtopic.php?f=3&t=9975)

The board circuit diagram:

![Circuit diagram](/65816-TUBE.svg)

**Take care if you build anything from the above schematic, I have not checked that all the bugs were ironed out! Take special care around the power pins!**

The whole setup plugs into a BBC Micro Tube port via a [Tube Silencer] http://www.zeridajh.org/hardware/tubesilencer/index.htm which interfaces a DE0 nano to the beeb. The 65816 board then plugs direct into the second GPIO connector of the DE0 nano.


