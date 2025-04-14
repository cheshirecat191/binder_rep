- written in R / Shiny
- using github on https://github.com/cheshirecat191/binder_rep
- uploaded to mybinder.org https://mybinder.org/v2/gh/cheshirecat191/binder_rep.git/HEAD?urlpath=shiny/shiny/
- R version 4.3.2 (2023-10-31)
- data file: CAPT_CHLGE_20250331.fgb
---
- The app uses a drop down menu to manually select the species (list automatically generated) from all available species in the imported fgb file. The first (Capreolus capreolus) is selected automatically.

- Two optional histograms are shown below to illustrate the date of the observations and the occurring values for allochtonie.

- The species name, number of observations and the species ID are shown on the top of the map

- The map consists of a base map of Switzerland (2 options in the code) with the the locations of the observations as point data in the top later.
	
	- the locations of the observations (rows in the data base) are already assigned to this 5 km grid, so I am not carrying out additional aggregation.
	
	- another possibility might have been to plot a 5km x 5 km grid and assign the observations with the corresponding cell ID (N5) to the grid.
	
	- each set of coordinates has multiple points plotted superposed, this means only the last one plotted is visible (unless the symbols below are visible behind the top symbol).
	--> it is not clear if there are any points that have a higher priority (more recent / non-allochtonous...) which should have been plotted on top.
	--> per default the points are plotted in the order as they appear in the data frame, which could be adapted by some sorting if necessary.
	--> leaflet can show by marker clustering how many points are present in the same location, something like that could be useful. A kind of heat map would be interesting.
	--> I also had the idea to include checkboxes for subsetting / filtering the year ranges and the values for ALLOC to better view overlapping. This can be done with interactive functionalities in Shiny or by using leaflet.
	--> this was the reason why I added the two additional histograms, so at least there is some information if there are any data points (and how many) for old observations and non-autochton occurrences. 
	
	- I have used the symbols as requested in the task descrition, but 
	- The year ranges (beginning - 2009 and 2010 to end of timestamp) are distinguished by different colours (values of grey) - I assumed 2010 is included in the second range, but it was not clear from the sample pictures.

	- The values for ALLOC are shown as requested by square, circle and diamond 
	--> The type of symbol is fixed to the value of ALLOC.
	--> they only appear in the legend if the corresponding values are present in the subset of the data.
	--> sometimes the symbols are not well legible, especially when overlapping. See comments above.

- the observations of the juvenile / adult animals are given in percentage with the same scale. 
	- Since the percentage doesn't take into account the number ob observations, I thought it would be better to at least keep the same scale, which made the plot a bit larger. 
	- I chose to mirror it at the same axis, so in case of both juvenile and adult high occurrence at the same time the axes would not interfere with each other. 
	
- the plot of the altitude distribution is shown on the side
	- I have used the same bining as in the example, the values are calculated in percentage.
	- the plot uses demrcl, but it would also work in the same way with ALTdem. 
	

General comments:
	- some more statistics might be useful (proportion of plotted data points (because of NA) vs. total number of observations, for example for young / adult animals or autochtone / allochtone etc.)
	- data on adult / juvenile are derived from boolean entries, that also allow 1 / 1 (adult AND juvenile?). How does this work if one observation coresponds to one animal?
	- the locations are already spaced 5 km apart so I suspect they correspond to the desired grid, but it is not clear to me if the data on precision is included. 
	  If the precision exceeds the grid, in principle the observation should be entered in several grid cells, it is not clear wether this has already been done in the data set so i did not perform any further redistribution.
	- I did not reproduce the exact design of the example, I suppose that a different approach is used at infofauna anyways and possibly certain design rules are given.