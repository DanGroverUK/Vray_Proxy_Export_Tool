Rollout MyRoll "Vrmesh Exp 1.9 DG"
  (
	group "Export Script..."
	(
	spinner facecount "Face Count:" range:[0,5000000,100000] scale:1000
	checkbox slowbutsafe "Up to 6x slower - but safer!"
	checkbox printobjname "Display Object Name?"
	checkbox genlowpol "Generate Low Poly Mesh"
	spinner polypercent "LowPoly Percentage" enabled:false range:[0,100,10]
	button go "Publish"
	progressbar progress color:green
	edittext info text:"Waiting..." readonly:true
	)
	group "Other Crap..."
	(
		button convert "Convert All Selected to Poly"
		button deletehidden "Delete All Hidden Objects"
		button ungroundsafely "Ungroup Objects Safely"
		button ifcrash "Press If Crashed"
		progressbar progressothercrap color:green
	)
	  

on ifcrash pressed do
(
	fetchmaxfile quiet:true
	enablesceneredraw()
)
	
on ungroundsafely pressed do
(
	objectstoexplode = #()
	counter3 = 0
	total = objects.count
	for g in objects do
	(	
		join objectstoexplode g
	)
	for k in 1 to objectstoexplode.count do
	(
		info.text = ("Ungrouping " + (objectstoexplode[k].name as string))
		counter3 = counter3 + 1
		progressothercrap.value = (100.00 * counter3) / total
		windows.processPostedMessages()
		explodegroup objectstoexplode[k]
	)
	progressothercrap.value = 0
	g = 0
	k = 0
	info.text = "Waiting..."
	windows.processPostedMessages()
)
	
on deletehidden pressed do
(
	deathlist = #()
	counter2 = 0
	total = objects.count
	for g in objects do
	(
		if g.ishidden ==true do
		(
			print g
			join deathlist g
		)
		counter2 = counter2 + 1
		progressothercrap.value = (100.00 * counter2) / total
		windows.processPostedMessages()
	)
	delete deathlist
	progressothercrap.value = 0.0
)

on genlowpol changed theState do
(
	if genlowpol.checked == true then
	(
		polypercent.enabled = true
	)
	else
	(
		polypercent.enabled = false
	)
)
	
	on convert pressed do
	(
		f = undefined
		total = selection.count
		counter2 = 0
		for f in selection do
		(
			converttopoly f
			print f
			counter2 = counter2 + 1
			progressothercrap.value = (100.00 * counter2) / total
			windows.processPostedMessages()
		)
		f = undefined
		info.text = "Waiting..."
		windows.processPostedMessages()
		progressothercrap.value = 0
	)
	
on go pressed do
	  (
				-- hold file so as to restore multiple objects
				info.text = "Temporary Save In Process"
				windows.processPostedMessages()
				holdmaxfile()
				  --turn off screen redraw
				  disableSceneRedraw()
					setCommandPanelTaskMode #create
				  --sets silent mode
				  setsilentmode on
				  -- resets progress bar counter
				  count = 0
				-- unlink everything
				select objects
				max unlink $
				max group ungroup
				info.text = "Validation..."
				windows.processPostedMessages()
				deselect $
					---------
					-- checks for splines that are renderable, and converts them to mesh
					for d in shapes do
					(
						if ((classof d) == LinkCompositeshape) do 
						(
							converttomesh d
							windows.processPostedMessages()
						)
					)
					for e in shapes do
					(
						if e.render_renderable == true do
						(
							converttomesh e
							windows.processPostedMessages()
						)
					)
				  --delete the vray proxies
				info.text = "Deleting Proxies..."
				windows.processPostedMessages()
				  proxylist = #()
					for c in geometry do
					(
						if ((classof c) == VRayProxy) then
						(
							--add all the proxies to an array - otherwise geometry loop screws up
							join proxylist c
							windows.processPostedMessages()
						)
						-- a bit cheeky here, but adding linkcomposite items to the soon-to-be-deleted proxy list
						if ((classof c) == LinkComposite) then
						(
							join proxylist c
							windows.processPostedMessages()
						)
						else
						()
					)
					--delete all the proxies
					delete proxylist
					-- defines the total object count to avoid the number going down during script running!
					total = geometry.count
					info.text = "Converting + Attaching Objects..."
					windows.processPostedMessages()
						a = 1
						attachlist = #()
						for k in geometry do
						(
							join attachlist k
						)
						undo off
						(
							while attachlist.count > 1 do
							(
								--checks to see if the object is hidden
								if attachlist[a].ishidden == false do
								(
										--converts ALL geometry to poly to avoid future problems with funny mesh and instanes
										if slowbutsafe.checked == true do
										(
											if classof attachlist[a] != Editable_mesh do
											(
												if classof attachlist[a] != Editable_poly do
												(
													windows.processPostedMessages()
													converttopoly attachlist[a]										
												)
											)
										)
										-- attach all objects to the selected
										aname = (attachlist[a].name as string)
										trimright aname "!£$%^&*()._ :"
										windows.processPostedMessages()
										if classof attachlist[a] != Editable_Poly then converttopoly attachlist[a]
  										polyop.attach attachlist[a] attachlist[a+1]
										deleteItem attachlist (a+1)
										a += 1
										if (a + 1) > geometry.count then a = 1
										count += 1
										progress.value = (100.00 * count) / total
										if printobjname.checked == true do
										(
											info.text = ("Processing " + (aname as string) + " now!")
										)
										windows.processPostedMessages()
								)
								if (a +1) > attachlist.count then a = 1
							)
						)
						select geometry[1]
					-- store the location of the center of the object
					--pivotpoint = geometry[1].pos
					multisub = $.material
					-- get the current maxfile name sans extention
					info.text = "Exporting .vrmesh..."
					windows.processPostedMessages()
					vrname = maxfilename
					newname = ""
					for b in 1 to (vrname.count - 4) do 
						(
							newname = (newname + vrname[b])
						)
					--reset xform
					resetxform $
					centerpivot $
					converttopoly $
					-- vraymeshexport
					vrayMeshExport meshfile:(maxfilepath+newname) exportmultiple:false maxPreviewFaces:facecount.value
					--if the low poly export button is checked, it changes the object name, adds the prooptimiser, collapses and exports the mesh as a temp max file. 
					if genlowpol.checked == true do
					(
						$.name = (newname + ("_LowPoly"))
						tocenter = $.name
						info.text = "Reducing Poly Count..."
						windows.processPostedMessages()	
						polycrunch = (polypercent.value as integer)
						setCommandPanelTaskMode #modify
						modPanel.addModToSelection (ProOptimizer vertexpercent:polycrunch)
						if polycrunch != 100 do
						(
							$.prooptimizer.calculate = true
						)
						converttopoly $
						info.text = "Exporting Attached Geometry!"
						windows.processPostedMessages()
						savenodes $ (maxfilepath + "\\temp_file.max")
					)
					info.text = "Loading Temp Save"
					windows.processPostedMessages()
					--fetch max file
					fetchmaxfile quiet:true
					-- import the proxy
					info.text = "Importing .vrmesh File..."
					windows.processPostedMessages()
					importedproxy = vrayproxy filename:(maxfilepath+newname+".vrmesh") /*pos:pivotpoint*/ name:newname material:multisub
					centerpivot importedproxy
					--imports the previously generated lowpoly model
					if genlowpol.checked == true do
					(
						info.text = "Importing LowPoly Mesh..."
						windows.processPostedMessages()
						mergemaxfile (maxfilepath + "\\temp_file.max") #noRedraw #select #mergeDups #renameMtlDups #neverReparent quiet:true
						--centerpivot $
						info.text = "Moving LowPoly Mesh..."
						windows.processPostedMessages()
						currentlocation = $.pos
						$.pos = [0,0,0]
						polyop.movevert $ #all currentlocation	
						resetxform $
					)
					info.text = "All done!"
				--disable screen redraw
					enablesceneredraw()
				--sets silent mode
					setsilentmode off
		)
		
	)--end rollout
  createdialog MyRoll height:345 width:250