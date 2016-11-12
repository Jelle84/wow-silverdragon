-- DO NOT EDIT THIS FILE; run dataminer.lua to regenerate.
local core = LibStub("AceAddon-3.0"):GetAddon("SilverDragon")
local module = core:NewModule("Data_Wrath")

function module:OnInitialize()
	core:RegisterMobData("Wrath", {
		[32357] = {name="Old Crystalbark",locations={[486]={20602760,22003340,29803260,34002420,35402940,21002840,22003360,27003560,34002400},},},
		[32358] = {name="Fumblub Gearwind",locations={[486]={59801800,59802540,62203300,65201800,67403640,67602560,73603260,59801460,62002560,64003520,65801740,67802880,70803660},},},
		[32361] = {name="Icehorn",locations={[486]={80404600,81203160,88203960,91403240,80604620,81403140,88203960,91403200},},tameable=true,},
		[32377] = {name="Perobas the Bloodthirster",locations={[491]={50200480,52801160,60802020,68401700,49800460,52801160,60802000,68201720},},},
		[32386] = {name="Vigdis the War Maiden",locations={[491]={69405820,69804940,71404420,74405640,74805100,68204680,69805720,72804040,74605100},},},
		[32398] = {name="King Ping",locations={[491]={26006400,30807120,31205680,33208020,26006380,30807120,31205660,32807980},},},
		[32400] = {name="Tukemuth",locations={[488]={54405540,57004980,58603920,59402880,61405960,62204460,62605100,63603720,66803180,67805960,68004600,54205600,57804640,58404080,60603020,61805660,66803280,67404340,68805780,70005140},},},
		[32409] = {name="Crazed Indu'le Survivor",locations={[488]={15404520,15405820,20605520,26405800,33205680,15405820,15604560,24005440,28406140},},},
		[32417] = {name="Scarlet Highlord Daion",locations={[488]={69207480,71202240,85803660,86804160,69207540,71002220,75202760,85803660},},},
		[32422] = {name="Grocklar",locations={[490]={10603920,11207100,12005560,12204440,12805000,17207040,21405700,22407320,28004180,11805520,12004460,12207080,18007140,24005480},},},
		[32429] = {name="Seething Hate",locations={[490]={28004540,34004920,40004840,34204920,40004980},},},
		[32435] = {name="Vern",locations={[504]={51203140,57003080},},tameable=true,},
		[32438] = {name="Syreian the Bonecarver",locations={[490]={61203520,65202940,66203560,66404140,71203460,73804240,62803700,65002980,70203280,74204240},},},
		[32447] = {name="Zul'drak Sentinel",locations={[496]={21208260,26208280,28807220,40405240,40405800,42207000,45806040,45807580,50208320,22008280,28208260,29007520,40405460,40406000,42607060,46207680,46406540,49808240},},},
		[32471] = {name="Griegen",locations={[496]={14405620,17407140,21007940,22406180,26205560,26407120,17407020,20807880,26607100},},},
		[32475] = {name="Terror Spinner",locations={[495]={71607500},[496]={53203140,61203640,71402320,71402900,74406640,77204220,81403440,53203140,60603680,71002880,71602380,74406640,77204260,81203460},},tameable=true,},
		[32481] = {name="Aotona",locations={[493]={40205900,41206840,41407380,42205180,52407240,54405180,57406560,39805820,41206820,41807380,46605560,52407140,54405120,57206460},},tameable=true,},
		[32485] = {name="King Krush",locations={[493]={25804880,29204220,32603540,37002960,47004340,50808000,52204240,58808180,63808280,26204780,30403980,33403380,46804260,50808140,52004280,56008460,61208320},},tameable=true,},
		[32487] = {name="Putridus the Ancient",locations={[492]={44005820,45205020,54004120,61004180,65004740,66205260,67405800,68406480,44405400,45206120,47804720,50004200,56204060,63404300,65605080,67405820,68406420},},},
		[32491] = {name="Time-Lost Proto-Drake",locations={[495]={28006540,36606980,39408440,28606440,31006940,35607660,27205660,28405140,31603800,40205980,50004800},},mount=true,},
		[32495] = {name="Hildana Deathstealer",locations={[492]={28604540,31604000,57805460,29603800,30803280,31204320,36802540,54005300,59605940},},},
		[32500] = {name="Dirkee",locations={[495]={37805840,41005140,41404040,68004740,37805800,41005180,41404020,68004760},},},
		[32501] = {name="High Thane Jorfus",locations={[492]={31206220,31606720,46808520,47407840,67603860,72803500,31206240,33607060,47407820,48408500,69804080,72403560},},},
		[32517] = {name="Loque'nahak",locations={[493]={21407020,30206660,35402960,50008160,58402140,66007900,70807120,21407020,30606540,35603080,50808120,57802240,66607840,71607120},},tameable=true,},
		[32630] = {name="Vyragosa",locations={[495]={26204180,26405980,28406520,31404860,32003760,34206600,36407580,37608320,38406000,41206800,44205820,45203120,47608160,48406640,49407200,51803060,27006260,29806780,31203800,34004500,35407680,36806800,38008340,41006180,47006380,51207100,26007320},},},
		[33776] = {name="Gondria",locations={[496]={61406120,63004300,67407760,69404800,77006940,61006160,63204340,67607740,77607000},},tameable=true,},
		[35189] = {name="Skoll",locations={[495]={27805040,30206440,46206440,27805080,30206460,46006500},},tameable=true,},
		[38453] = {name="Arcturis",locations={[490]={31005580,30605600},},tameable=true,},
	})
end
