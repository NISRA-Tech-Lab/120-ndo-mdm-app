<script>
	import { base } from "$app/paths";
	import { goto } from "$app/navigation";
	import { suffixer, changeClass, changeStr } from "$lib/utils";
	import {
		geog_types,
		topics,
		mapStyle,
		mapSources,
		mapLayers,
		mapPaint,
		app_inputs,
	} from "$lib/config";
	import Section from "$lib/layout/Section.svelte";
	import Select from "$lib/ui/Select.svelte";
	import Map from "$lib/map/Map.svelte";
	import MapSource from "$lib/map/MapSource.svelte";
	import MapLayer from "$lib/map/MapLayer.svelte";
	import ScrollToTop from "$lib/ui/scroll.svelte";
	import SearchResult from "$lib/ui/SearchResult.svelte";
	import ScaleChart from "$lib/chart/ScaleChart.svelte";
    import ScaleChartMDM from "$lib/chart/ScaleChartMDM.svelte";

	export let data;
	let searchName;

	let w, cols;
	let map = null;
	let comp_2011 = false;
	let comp_ni = true;

	let active = {
		selected: null,
		type: null,
		childType: null,
		highlighted: [],
		hovered: null,
	};

	let isChild = {};
	Object.keys(mapLayers).forEach((key) => (isChild[key] = false));

	function makeDataNICompare(value) {
		let newdata = [];

		if (data.place.data.hasOwnProperty(value)) {
			let check_value = data.place.data[value].perc;
			let place_data;
			let ni_data;

			if (check_value.hasOwnProperty("2021")) {
				place_data = check_value["2021"];
				ni_data = data.ni.data[value].perc["2021"];
			} else {
				place_data = check_value;
				ni_data = data.ni.data[value].perc;
			}

			let category_lookup;
			let label_lookup;
			let v_topics = Object.keys(topics[value]);

			for (let i = 0; i < v_topics.length; i++) {
				for (let j = 0; j < Object.keys(place_data).length; j++) {
					if (
						topics[value][v_topics[i]].category ==
						Object.keys(place_data)[j]
					) {
						category_lookup = topics[value][v_topics[i]].category;
						label_lookup = topics[value][v_topics[i]].label;
						break;
					}
				}
				if (place_data[category_lookup] <= 100) {
					newdata.push({
						group: "Northern Ireland",
						category: label_lookup,
						perc: ni_data[category_lookup],
						width: 0,
					});
					if (data.place.name != "Northern Ireland") {
						newdata.push({
							group: data.place.name,
							category: label_lookup,
							perc: place_data[category_lookup],
							width: 0,
						});
					}
				}
			}
		}

		return newdata;
	}

	function fitMap(bounds) {
		if (map) {
			map.fitBounds(bounds, { padding: 20 });
		}
	}

	function updateActive(place) {
		let prev = JSON.parse(JSON.stringify(active));
		let code = data.place.code;
		let type = data.place.type;
		let children = data.place.children[0]
			? data.place.children.map((d) => d.code)
			: [];
		let childType =
			data.place.type == "rgn"
				? "cty"
				: children[0]
					? data.place.children[0].type
					: null;

		active.selected = code;
		active.type = type;
		active.childType = childType;
		active.highlighted = children;

		let keys = Object.keys(mapLayers);
		let fillProps = ["fill-color", "fill-opacity"];
		let lineProps = ["line-color", "line-width", "line-opacity"];

		// Change layer visibility and paint properties if geography level changes
		if (
			map &&
			(active.type != prev.type || active.childType != prev.childType)
		) {
			// Set map layer visibility properties
			keys.forEach((key) => {
				let visibility =
					key == type || (childType && key == childType)
						? "visible"
						: "none";
				map.setLayoutProperty(key + "-fill", "visibility", visibility);
				map.setLayoutProperty(
					key + "-bounds",
					"visibility",
					visibility,
				);
				if (data.place.type != "ni") {
					map.setLayoutProperty(
						key + "-self",
						"visibility",
						visibility,
					);
				}
				isChild[key] = key == childType ? true : false;
			});

			// Set new paint properties
			if (data.place.type != "ni") {
				fillProps.forEach((prop) =>
					map.setPaintProperty(
						type + "-fill",
						prop,
						mapPaint[children[0] ? "fill-active" : "fill-self"][
							prop
						],
					),
				);
				lineProps.forEach((prop) => {
					map.setPaintProperty(
						type + "-bounds",
						prop,
						mapPaint["line-active"][prop],
					);
					map.setPaintProperty(
						type + "-self",
						prop,
						mapPaint["line-self"][prop],
					);
				});
			}
			if (childType) {
				fillProps.forEach((prop) =>
					map.setPaintProperty(
						childType + "-fill",
						prop,
						mapPaint["fill-child"][prop],
					),
				);
				lineProps.forEach((prop) =>
					map.setPaintProperty(
						childType + "-bounds",
						prop,
						mapPaint["line-child"][prop],
					),
				);
			}
		}
	}

	function update(place) {
		updateActive(place);
		fitMap(data.place.bounds);
	}

	function mapSelect(ev) {
		goto(`${base}/${ev.detail.code}/`, { noScroll: true, keepFocus: true });
	}

	function menuSelect(ev) {
		const name = ev.detail.selected.name;
		localStorage.setItem("search_name", name);
		searchName = name;
		goto(`${base}/${ev.detail.value}/`, {
			noScroll: true,
			keepFocus: true,
		});
	}

	function onResize() {
		cols =
			w < 575
				? 1
				: window
						.getComputedStyle(grid)
						.getPropertyValue("grid-template-columns")
						.split(" ").length;
	}

	$: w && onResize();
	$: chartLabel = comp_2011
		? "Same area 2011"
		: data.place && data.place.type != "ni"
			? "NI 2021"
			: null;

	$: chart_compare_type = comp_none
		? null
		: comp_2011
			? "prev"
			: !comp_2011 && data.place.type != "ni"
				? "ni"
				: null;

	$: data.place && update(data.place);
	$: comp_ni = true;
	$: comp_none = false;

	$: searchName = localStorage.getItem("search_name")

	function returnPct(expr) {
		let pct = (expr * 100).toFixed(1);

		if (pct < 0.1) {
			return "<0.1%";
		} else {
			return pct + "%";
		}
	}

	function returnRank(expr) {
		if (expr == 1) {
			return "largest";
		} else if (expr == data.place.count) {
			return "smallest";
		} else {
			return expr + suffixer(expr) + " largest";
		}
	}

	function popChange(place) {
		let output = "";

		if (place.data.hasOwnProperty("PopChange")) {
			let p_data = place.data.PopChange.value;
			let latest_year = Object.keys(p_data).slice(-1);
			let comparison_year = latest_year - 10;
			let change =
				((p_data[latest_year] - p_data[comparison_year]) /
					p_data[comparison_year]) *
				100;
			let change_word;

			if (change < 0) {
				change_word = "Down";
			} else if (change > 0) {
				change_word = "Up";
			}

			output =
				"<p>The population of " +
				place.name +
				" in " +
				comparison_year +
				' was <span class="text-big">' +
				p_data[comparison_year].toLocaleString() +
				"</span> and in " +
				latest_year +
				' was <span class="text-big">' +
				p_data[latest_year].toLocaleString() +
				'</span><p><span class="em ' +
				changeClass(change) +
				'">' +
				change_word +
				" " +
				changeStr(change, "%", 1) +
				"</span> since " +
				comparison_year +
				" Mid-Year Population Estimate</p>";
		}

		return output;
	}

	function check(value) {
		let value_dotted = value.replaceAll("[", ".").replaceAll("]", "");
		let props = value_dotted.split(".");

		let rtn_value = data.place.data;

		for (let i = 0; i < props.length; i++) {
			if (rtn_value.hasOwnProperty(props[i])) {
				rtn_value = rtn_value[props[i]];
			} else {
				rtn_value = [];
			}
		}

		if (rtn_value === null) {
			rtn_value = 0;
		}
		return rtn_value;
	}

	function compareNIrate(value) {
		let value_dotted = value.replaceAll("[", ".").replaceAll("]", "");
		let props = value_dotted.split(".");

		let rtn_value = data.ni.data;
		let rtn_value_place = check(value);

		if (
			(props[0] == "grouped_data_nocompare") |
			(props[0] == "grouped_data_areacompare")
		) {
			rtn_value = data.ni;
		}

		for (let i = 0; i < props.length; i++) {
			if (rtn_value.hasOwnProperty(props[i])) {
				rtn_value = rtn_value[props[i]];

				// if (props[i] == "perc") {
				// 	rtn_value = rtn_value.toFixed(0) + "%";
				// }
			} else {
				rtn_value = [];
			}
		}

		if (rtn_value_place > rtn_value + 2) {
			rtn_value = "<p>This is higher than the NI value</p>";
		} else if (rtn_value_place < rtn_value - 2) {
			rtn_value = "<p>This is lower than the NI value</p>";
		} else {
			rtn_value = "<p>This is similar to the NI value</p>";
		}

		return rtn_value;
	}

	function gps(value, place) {
		if (check(value) > 0 && place.name == "Northern Ireland") {
			return (
				"<p><span class='text-big'>" +
				check("GP.value.PRACS").toLocaleString() +
				"</span> GP practices with an average of <span class='text-big'>" +
				check("GP.value.PRACLIST").toLocaleString() +
				"</span> patients per practice.</p>"
			);
		} else if (check(value) > 0 && place.name != "Northern Ireland") {
			return (
				"<p><span class='text-big'>" +
				check("GP.value.PRACS").toLocaleString() +
				"</span> GP practices with an average of <span class='text-big'>" +
				check("GP.value.PRACLIST").toLocaleString() +
				"</span> patients per practice.</p>" +
				"<p>" +
				compareNIrate("GP.value.PRACLIST").toLocaleString() +
				"<span style='color: #1460aa'> (NI " +
				data.ni.data.GP.value.PRACLIST.toLocaleString() +
				" patients per practice) </span></p>"
			);
		} else {
			return "<p><span class='text-big'>0</span> GP practices.</p>";
		}
	}
	function pullYear(value, place) {
		if (place.meta_data.hasOwnProperty(value)) {
			return place.meta_data[value][0].year;
		} else {
			return null;
		}
	}

	function pullCensusYear(value) {
		if (data.place.data.hasOwnProperty(value)) {
			return (
				Object.keys(data.place.data[value].perc).slice(-1) + " Census"
			);
		} else {
			return null;
		}
	}

	function popDen(place) {
		let pop_den = place.data.MYETotal.value / (place.hectares / 100);

		if (pop_den < 10) {
			pop_den = "<10";
		} else {
			pop_den = (Math.round(pop_den * 10) / 10).toLocaleString(
				undefined,
				{ minimumFractionDigits: 1 },
			);
		}

		return pop_den;
	}

	function moreData(subject, place) {
		// if (place.type != "ni") {
		// 	return "You can also explore " + subject + " data for <a href = '" + base + "/" + place.parents[0].code + "/' data-sveltekit-noscroll data-sveltekit-keepfocus>" + place.parents[0].name + " </a>";
		// } else {
		// 	return "";
		// }

		if (place.type == "ni") {
			return "";
		} else if (place.type == "lgd") {
			return (
				"You can also explore " +
				subject +
				" data for <a href = '" +
				base +
				"/" +
				place.parents[0].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[0].name +
				"</a>"
			);
		} else if (place.type == "dea") {
			return (
				"You can also explore " +
				subject +
				" data for <a href = '" +
				base +
				"/" +
				place.parents[0].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[0].name +
				"</a>" +
				" and <a href = '" +
				base +
				"/" +
				place.parents[1].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[1].name +
				"</a>"
			);
		} else if (place.type == "sdz") {
			return (
				"You can also explore " +
				subject +
				" data for <a href = '" +
				base +
				"/" +
				place.parents[0].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[0].name +
				"</a>" +
				", <a href = '" +
				base +
				"/" +
				place.parents[1].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[1].name +
				"</a>" +
				" and <a href = '" +
				base +
				"/" +
				place.parents[2].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[2].name +
				"</a>"
			);
		} else if (place.type == "dz") {
			return (
				"You can also explore " +
				subject +
				" data for <a href = '" +
				base +
				"/" +
				place.parents[0].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[0].name +
				"</a>" +
				", <a href = '" +
				base +
				"/" +
				place.parents[1].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[1].name +
				"</a>" +
				", <a href = '" +
				base +
				"/" +
				place.parents[2].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[2].name +
				"</a>" +
				" and <a href = '" +
				base +
				"/" +
				place.parents[3].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[3].name +
				"</a>"
			);
		}
	}

	function parentlinks(place, data_avail) {
		// data_avail - can be ni and lgd, ni and dea or ni, lgd and dea

		if (place.type == "ni") {
			return "";
		} else if ((place.type == "dea") & (data_avail == "ni, lgd")) {
			return (
				"<a href = '" +
				base +
				"/" +
				place.parents[0].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[0].name +
				"</a>" +
				" and <a href = '" +
				base +
				"/" +
				place.parents[1].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[1].name +
				"</a>"
			);
		} else if ((place.type == "sdz") & (data_avail == "ni, lgd")) {
			return (
				"<a href = '" +
				base +
				"/" +
				place.parents[1].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[1].name +
				"</a>" +
				" and <a href = '" +
				base +
				"/" +
				place.parents[2].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[2].name +
				"</a>"
			);
		} else if ((place.type == "dz") & (data_avail == "ni, lgd")) {
			return (
				"<a href = '" +
				base +
				"/" +
				place.parents[2].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[2].name +
				"</a>" +
				" and <a href = '" +
				base +
				"/" +
				place.parents[3].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[3].name +
				"</a>"
			);
		} else if ((place.type == "lgd") & (data_avail == "ni, dea")) {
			return (
				"<a href = '" +
				base +
				"/" +
				place.parents[0].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[0].name +
				"</a>"
			);
		} else if ((place.type == "sdz") & (data_avail == "ni, dea")) {
			return (
				"<a href = '" +
				base +
				"/" +
				place.parents[0].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[0].name +
				"</a>" +
				" and <a href = '" +
				base +
				"/" +
				place.parents[2].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[2].name +
				"</a>"
			);
		} else if ((place.type == "dz") & (data_avail == "ni, dea")) {
			return (
				"<a href = '" +
				base +
				"/" +
				place.parents[2].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[2].name +
				"</a>" +
				" and <a href = '" +
				base +
				"/" +
				place.parents[3].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[3].name +
				"</a>"
			);
		} else if ((place.type == "sdz") & (data_avail == "ni, lgd, dea")) {
			return (
				"<a href = '" +
				base +
				"/" +
				place.parents[0].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[0].name +
				"</a>, " +
				"<a href = '" +
				base +
				"/" +
				place.parents[1].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[1].name +
				"</a>" +
				" and <a href = '" +
				base +
				"/" +
				place.parents[2].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[2].name +
				"</a>"
			);
		} else if ((place.type == "dz") & (data_avail == "ni, lgd, dea")) {
			return (
				"<a href = '" +
				base +
				"/" +
				place.parents[1].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[1].name +
				"</a>, " +
				"<a href = '" +
				base +
				"/" +
				place.parents[2].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[2].name +
				"</a>" +
				" and <a href = '" +
				base +
				"/" +
				place.parents[3].code +
				"/' data-sveltekit-noscroll data-sveltekit-keepfocus>" +
				place.parents[3].name +
				"</a>"
			);
		}
	}

	function compareDensity(place) {
		let pop_den = place.data.MYETotal.value / (place.hectares / 100);

		let ni_pop_den = data.ni.data.MYETotal.value / (data.ni.hectares / 100);

		let comparison = pop_den / ni_pop_den;

		if (comparison < 0.8) {
			comparison = "Lower than the Northern Ireland average";
		} else if (comparison.toFixed(0) > 1) {
			comparison =
				'Approximately <span class = "em" style = "background-color: lightgrey">' +
				comparison.toFixed(0) +
				" times </span> the Northern Ireland average";
		} else if (comparison.toFixed(0) == 1) {
			comparison =
				'Approximately <span class = "em" style = "background-color: lightgrey">the same density level</span> as the Northern Ireland average';
		} else {
			comparison =
				'Approximately <span class = "em" style = "background-color: lightgrey">1/' +
				(1 / comparison).toFixed(0) +
				" </span> of the Northern Ireland average";
		}

		return comparison;
	}


</script>

<svelte:head>
	<title>{data.place.name} Multiple Deprivation Measures</title>
	<meta name="description" content="" />
	<meta property="og:title" content="{data.place.name} Mutliple Deprivation Measures" />
	<meta property="og:type" content="website" />
	<meta property="og:url" content="{app_inputs.base}/{data.place.code}/" />
	<meta
		property="og:description"
		content="Explore NISRA Statistics for {data.place.name}."
	/>
	<meta
		name="description"
		content="Explore NISRA Statistics for {data.place.name}."
	/>
</svelte:head>
<ScrollToTop />
<Section column="wide">
	{#if data.place && data.ni}
		<div class="grid mtl">
			<div>
				<p>
					<span>
						<a
							href="{base}/"
							data-sveltekit-noscroll
							data-sveltekit-keepfocus>Home</a
						>{@html " &gt; "}
						{#if data.place.type != "ni"}
							{#each [...data.place.parents].reverse() as parent, i}
								<a
									href="{base}/{parent.code}/"
									data-sveltekit-noscroll
									data-sveltekit-keepfocus>{parent.name}</a
								>{@html " &gt; "}
							{/each}
						{/if}
					</span>
				</p>
				<br />
				{#if data.place.type == "sdz"}
					<span
					class="text-big title"
					style="font-size: 2.0em; line-height: 1em;"
					>How deprived is {searchName}?</span
				>
				{:else}
				<span
					class="text-big title"
					style="font-size: 2.5em; line-height: 1em;"
					>{data.place.name.replace(/_/g, " ")}</span
				>
				{/if}
			</div>

			<div>
				<div
					style="width: 350px; padding-top: 5px;"
					class:float-right={cols > 1}
				>
					<p>Search for your area:</p>
					<Select
						search_data={data.search_data}
						group="typestr"
						search={true}
						on:select={menuSelect}
					/>

					<!-- Code credit: https://css-tricks.com/on-the-web-share-api/ -->

					<script>
						// Share button
						// Possible tooltip: https://stackoverflow.com/questions/37798967/tooltip-on-click-of-a-button

						function copyToClipboard(text) {
							var inputc = document.body.appendChild(
								document.createElement("input"),
							);
							inputc.value = window.location.href;
							inputc.select();
							document.execCommand("copy");
							inputc.parentNode.removeChild(inputc);
							alert("URL Copied.");
						}

						(function (win, doc) {
							const testButton = doc.createElement("button");
							testButton.setAttribute("type", "share");
							if (testButton.type != "share") {
								win.addEventListener("click", function (ev) {
									ev = ev || win.event;
									let target = ev.target;
									let button = target.closest(
										'button[type="share"]',
									);
									if (button) {
										const title = "Share URL";
										const url = win.location.href;
										if (navigator.share) {
											navigator.share({
												title: title,
												url: url,
											});
										} else {
											copyToClipboard();
										}
									}
								});
							}
						})(this, this.document);
					</script>

					<div width="100%">
						<button
							class="btn"
							style="width: 32.5%"
							alt="Opens the About page"
							onclick="window.location.href='{base}/about';"
							>About
						</button>
						<button
							class="btn"
							style="width: 32.5%"
							title="Click to print this page to pdf or printer"
							onclick="window.print();return false;"
							>Print / PDF
						</button>
						<button
							class="btn"
							style="width: 32.5%"
							type="share"
							alt="Share this page"
							>Share
						</button>
					</div>
				</div>
			</div>
		</div>

		<SearchResult place={data.place} />

	

		<div id="grid" class="grid mt"></div>
		<!-- a19e9e -->
		<div class="grid mt" bind:clientWidth={w}>
			<div style="grid-column: span {cols};">
				<h3>
					<!-- Explore <span style="color: #93328E">{data.place.name}</span> -->
					{#if data.place.type != "ni"}
						You are currently viewing <span style="color: var(--nisra_blue)"
							>{data.place.name}
						</span>
						{geog_types[data.place.type].name}
						<span style="color: var(--nisra_navy)">
							<!-- {geog_types[data.place.type].name} -->
						</span>
						<p>
							<span class="text-bold"
								>Zoom and click on map to explore other areas
							</span>
						</p>
					{:else}
						<p class="text-bold">
							Zoom and click on map to explore other areas
						</p>
						<!-- <span style="color: var(--nisra_blue)">{data.place.name}</span> -->
					{/if}
				</h3>
			</div>
			{#if data.place.type == "sdz"}
			<div class="deprivation-box">
				<h2>Overall deprivation rank:</h2>
					<h2 class="rank-value">{data.place.data.ranks.mdm} out of {data.place.count}</h2>
						<br>
							<p class="box-text">1 is the most deprived neighbourhood in Northern Ireland
								{data.place.count} is the least
							</p>
			</div>
			{/if}
			<div
				id="map"
				style="padding-right: 45px; grid-column: span {cols == 2
					? 2
					: cols && cols > 2
						? cols - 1
						: 1};  "
			>
				<Map
					bind:map
					location={{ bounds: data.place.bounds }}
					options={{ fitBoundsOptions: { padding: 20 } }}
					style={mapStyle}
				>
					{#each ["dz", "sdz", "dea", "lgd"] as key}
						<MapSource {...mapSources[key]}>
							<MapLayer
								{...mapLayers[key]}
								id="{key}-fill"
								type="fill"
								isChild={isChild[key]}
								click={true}
								selected={active.selected}
								on:select={mapSelect}
								highlight={true}
								highlighted={active.highlighted}
								hover={true}
								hovered={active.hovered}
								layout={{
									visibility:
										active.type == key ||
										active.childType == key
											? "visible"
											: "none",
								}}
								paint={active.type == key
									? mapPaint["fill-self"]
									: active.childType == key
										? mapPaint["fill-child"]
										: mapPaint.fill}
							/>
							<MapLayer
								{...mapLayers[key]}
								id="{key}-bounds"
								type="line"
								selected={active.selected}
								highlight={true}
								highlighted={active.highlighted}
								layout={{
									visibility:
										active.type == key ||
										active.childType == key
											? "visible"
											: "none",
								}}
								paint={active.type == key
									? mapPaint["line-active"]
									: active.childType == key
										? mapPaint["line-child"]
										: mapPaint.line}
							/>
							<MapLayer
								{...mapLayers[key]}
								id="{key}-self"
								type="line"
								selected={active.selected}
								layout={{
									visibility:
										active.type == key ? "visible" : "none",
								}}
								paint={active.type == key
									? mapPaint["line-self"]
									: mapPaint.line}
							/>
						</MapSource>
					{/each}
				</Map>
			</div>
			{#if data.place.type == "sdz"}
				<p class="sdz-map-info">
					{#if searchName.startsWith("BT")}
					{searchName} sits in the {data.place.name.replace(/_/g, ' ')}
					neighbourhood. 
					{/if}
					{data.place.name.replace(/_/g, ' ')} has a population of {data.place.data.population.toLocaleString()}
					and is classified as {data.place.data.urban_rural}.
				</p>
				{/if}
			<div>
				{#if data.place.type != "ni"}
					<span class="text-bold"
						>Select a larger area containing {data.place.name}
					</span>
					<span class="text-small">
						{#each [...data.place.parents].reverse() as parent, i}
							<span
								style="display: block; margin-left: {i > 0
									? (i - 1) * 15
									: 0}px"
								>{@html i > 0 ? "↳ " : ""}<a
									href="{base}/{parent.code}"
									data-sveltekit-noscroll
									data-sveltekit-keepfocus>{parent.name}</a
								></span
							>
						{/each}
					</span>
				{/if}
			</div>
			<div>
				{#if data.place.children[0]}
					<span class="text-bold"
						>Select a {data.place.children[0]
							? geog_types[data.place.children[0].type].name
							: "Areas"} within {data.place.name}</span
					><br />
					<span class="text-small">
						{#each data.place.children as child, i}
							<a
								href="{base}/{child.code}"
								data-sveltekit-noscroll
								data-sveltekit-keepfocus>{child.name}</a
							>{i < data.place.children.length - 1 ? ", " : ""}
						{/each}
					</span>
				{:else}
					<span class="muted"
						>No areas below {data.place.name}
						{geog_types[data.place.type].name}</span
					>
				{/if}
			</div>
		</div>
	{/if}
</Section>
{#if data.place.type == "sdz"}
	<div class="mdm-rank-text">
		<Section column="wide">
			<h2 class="deprivation-headline">
				<span style="color: var(--nisra_blue);">
        			{data.place.name.replace(/_/g, " ")}
    			</span>
 					is {#if data.place.data.ranks.mdm < (data.place.count / 2)}
						<span>more</span>
						{:else}
						<span>less</span>
					{/if} deprived than most neighbourhoods in Northern Ireland.
			</h2>
		</Section>
	</div>

	<Section>
		<ScaleChartMDM value={data.place.data.ranks.mdm} place={data.place}></ScaleChartMDM>
	</Section>
{/if}


<Section column="wide">
	<h2>There are different types of deprivation in <span style="color: var(--nisra_blue);">{data.place.name.replace(/_/g, " ")}</span></h2>
	<div class="grid">
		<div style="grid-column: span 1;">
			<p style="margin-bottom: 0;">Income</p>
			<p style="margin-top: 0;">rank {data.place.data.ranks.income}</p>
		</div>
		<div style="grid-column: span 2;">
			<ScaleChart value = {data.place.data.ranks.income} />
		</div>
		
	</div>
	
</Section>
<style>

	.deprivation-headline{
		text-align: center;
	}

	.mdm-rank-text {
	margin: 20px;
	}

	.deprivation-box {
    background: #efefef;          
    border: 2px solid #2b3a42;    
    padding: 10px 10px;
	margin-top: 10px;
    width: 100%;
    max-width: 350px;
    box-sizing: border-box;
	}

	.deprivation-box h2 {
    white-space: nowrap;
	text-align: center;
	}

	.rank-value {
    margin: 15px 0;
    font-size: 1.8rem;
    font-weight: 600;
    color: #00205b;
	text-align: center;
	}

	.box-text {
		text-align: center;
	}

	h3 {
		margin-top: 12px;
	}
	.btn {
		padding: 2px 4px;
		margin: 0.2;
		border: 2px solid #000000;
		cursor: pointer;
		color: #ffffff;
		background-color: var(--nisra_purple);
	}

	.title {
		display: inline-block;
		margin-top: -3px;
	}
	.float-right {
		float: right;
	}
	.mt {
		margin-top: 20px;
	}

	.mtl {
		margin-top: 25px;
	}
	.grid {
		display: grid;
		width: 100%;
		grid-gap: 10px;
		grid-template-columns: repeat(auto-fit, minmax(min(280px, 100%), 1fr));
		justify-content: stretch;
		page-break-inside: avoid;
	}

	#grid {
		grid-gap: 20px !important;
	}

	#map {
		grid-row: span 2;
		min-height: 400px;
	}

	@media print {
		* {
			-webkit-print-color-adjust: exact !important; /*Chrome, Safari */
			color-adjust: exact !important; /*Firefox*/
		}
	}
</style>
