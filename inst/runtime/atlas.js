'use strict';
(() => {
  const D = JSON.parse(document.getElementById('atlas-data').textContent);
  const legendOptions=D.legend || {},controlOptions=D.controls || {};
  const controlLabel=(key,fallback)=>controlOptions.labels?.[key] ?? fallback;
  const controlVisible=key=>controlOptions.visible?.[key]!==false;
  const fontStacks={system:'system-ui,sans-serif',sans:'Arial,Helvetica,sans-serif',serif:'Georgia,serif',mono:'ui-monospace,monospace'};
  const uiFont=fontStacks[D.style?.font_family] || fontStacks.system;
  const $ = id => document.getElementById(id), NS = 'http://www.w3.org/2000/svg';
  const nodes = (D.nodes || []).map(n => ({...n})), edges = D.edges || [], areas = (D.areas || []).map(a=>({...a}));
  const areaFrames=D.area_frames || [];
  const variables = D.variables || [], areaMode = !nodes.length;
  const mapHeight = D.coordinates === 'schematic' ? 650 : 520;
  const entityName=D.entity_name || 'entity', entityNames=D.entity_names || 'entities';
  const nodeById = new Map(nodes.map(n => [n.id, n]));
  const entities = areaMode ? areas : nodes, byId = new Map(entities.map(n => [n.id, n]));
  const layers = [...new Set(edges.map(e => e.layer))];
  const sources = [...new Set(edges.map(e => e.from))];
  const targets = [...new Set(edges.map(e => e.to))];
  const years = [...new Set([...edges.map(e => e.time).filter(t => t !== null),...areaFrames.map(f=>f.time)])].sort((a,b) => a.localeCompare(b, undefined, {numeric:true}));
  const colors = ['#176f70','#ad6738','#71558a','#346d9c','#9c5266','#566b32'];
  const fills = ['#edf4db','#c7dfb1','#8fc1a0','#4c9d91','#247577','#164c60'];
  const state = {year:D.controls.initial_time || years.at(-1) || null,
    source:D.controls.initial_source || '', selected:new Set(entities.map(n => n.id)),
    layers:new Set(layers), variable:0, size:'metric', background:true, inset:D.inset?.visible ?? false, zoom:1, dx:0, dy:0, query:''};
  const initial = {year:state.year, source:state.source};
  const baseCamera=(()=>{
    if(!D.view)return {zoom:1,dx:0,dy:0};
    const b=D.view,w=30+(b.west+180)/360*940,e=30+(b.east+180)/360*940;
    const n=92+(85-b.north)/145*380,s=92+(85-b.south)/145*380;
    const zoom=Math.min(940/(e-w),(mapHeight-60)/(s-n));
    return {zoom,dx:500-(w+e)/2*zoom,dy:mapHeight/2-(n+s)/2*zoom};
  })();Object.assign(state,baseCamera);
  const symbolScale=D.view ? baseCamera.zoom : 1;
  const svg = (tag, attrs={}, text) => {
    const element = document.createElementNS(NS, tag);
    if(tag==='text')attrs={...attrs,'font-family':uiFont};
    Object.entries(attrs).forEach(([k,v]) => element.setAttribute(k,v));
    if (text !== undefined) element.textContent = text;
    return element;
  };
  const text = (id, value) => $(id).textContent = value;
  const number = n => n === null ? 'Unavailable' : new Intl.NumberFormat('en-US',{maximumFractionDigits:2}).format(n);
  const short = n => n === null ? 'NA' : new Intl.NumberFormat('en-US',{notation:'compact',maximumFractionDigits:1}).format(n);
  const amount = n => n === null ? 'Unavailable' : `${number(n)}${D.units ? ' '+D.units : ''}`;
  const categoryMode=()=>areaMode && variables[state.variable]?.type==='categorical';
  const areaValue=(a,v)=>v?.type==='categorical' ? a[v.key] ?? 'Unavailable' : number(a[v?.key] ?? null);
  function applyAreaFrame() {
    if(!areaFrames.length)return;
    const frame=areaFrames.find(f=>f.time===state.year),lookup=new Map((frame?.data || []).map(a=>[a.id,a]));
    areas.forEach(a=>{const row=lookup.get(a.id);if(row)Object.assign(a,row);else {variables.forEach(v=>a[v.key]=null);a.matched=false;a.notes='No observation for this period.';}});
  }
  const name = id => byId.get(id)?.label || id;
  const active = () => edges.filter(e => (state.year === null || e.time === state.year) &&
    (!state.source || e.from === state.source) && state.layers.has(e.layer));
  const focusRows = rows => rows.filter(e => state.selected.has(e.from) || state.selected.has(e.to));
  const distinctPairs = rows => new Set(rows.map(e => JSON.stringify([e.from,e.to].sort()))).size;
  const degree = (rows,id) => new Set(rows.filter(e => e.from === id || e.to === id)
    .map(e => e.from === id ? e.to : e.from)).size;
  const known = rows => rows.filter(e => e.weight !== null);
  const total = rows => known(rows).length ? known(rows).reduce((sum,e) => sum + e.weight,0) : null;
  function summarize(es, id) {
    const ks = known(es), value = total(es);
    return {id, value, magnitude:ks.length ? ks.reduce((sum,e)=>sum+Math.abs(e.weight),0) : null, records:es.length, known:ks.length, partial:ks.length < es.length,
      status:!es.length ? 'No observation' : !ks.length ? 'Unavailable' : ks.length < es.length ? 'Partial' : value === 0 ? (D.signed && ks.some(e=>e.weight!==0) ? 'Net zero (offsetting flows)' : 'Recorded zero') : 'Observed'};
  }
  const incoming = (rows,id) => summarize(rows.filter(e => e.to===id || (!D.directed && e.from===id)),id);
  const outgoing = (rows,id) => summarize(rows.filter(e => e.from===id),id);
  const sizeValue = summary => D.signed ? summary.magnitude : summary.value;
  const allIncoming = years.length ? years.flatMap(y => nodes.map(n => sizeValue(incoming(edges.filter(e => e.time === y),n.id)) || 0)) : nodes.map(n => sizeValue(incoming(edges,n.id)) || 0);
  const sizeMax = Math.max(1,...allIncoming), edgeMax = Math.max(1,...edges.map(e => Math.abs(e.weight || 0)));
  function focusName() {
    return state.selected.size === entities.length ? `All ${entityNames}` : state.selected.size === 1 ? name([...state.selected][0]) : `${state.selected.size} ${entityNames} selected`;
  }
  function toggle(id) {
    if (state.selected.size === entities.length) state.selected.clear();
    if (state.selected.has(id)) state.selected.delete(id); else state.selected.add(id);
    render();
  }
  function option(select, value, label) {
    const o = document.createElement('option'); o.value = value; o.textContent = label; select.append(o);
  }
  function bindButton(element,id) {
    element.setAttribute('role','button'); element.setAttribute('tabindex','0');
    element.setAttribute('aria-label',`${name(id)}. Toggle selection.`);
    element.setAttribute('aria-pressed',String(state.selected.has(id)));
    element.addEventListener('keydown',e => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); toggle(id); } });
  }
  function lineColor(e) {
    if(D.signed)return e.weight < 0 ? colors[1] : colors[0];
    const index = layers.length > 1 ? layers.indexOf(e.layer) : sources.indexOf(e.from);
    return colors[(D.directed || layers.length > 1 ? index : 0) % colors.length];
  }
  function lineDash(e) {
    if(D.signed)return e.weight < 0 ? '7 4' : '';
    const i = layers.length > 1 ? layers.indexOf(e.layer) : sources.indexOf(e.from);
    return ['','7 4','2 4'][Math.max(0,i) % 3];
  }
  function areaColor(a) {
    const v = variables[state.variable]; if (!v) return '#e4eae2';
    const value = a[v.key]; if (value === null) return '#d8dbd7';
    if(v.type==='categorical')return v.colors[v.categories.indexOf(value)];
    return (v.colors || fills)[v.breaks.filter(b => value >= b).length];
  }
  function areaStatus(a,v) {
    if(a.matched===false)return 'No dataset match';
    return !v || a[v.key]==null ? 'Unavailable observation' : 'Observed';
  }
  function flowDetails(rows,id) {
    const groups=D.directed ? [
      ...(sources.includes(id) ? [{label:'Outgoing',records:rows.filter(e=>e.from===id),other:'to'}] : []),
      ...(targets.includes(id) ? [{label:'Incoming',records:rows.filter(e=>e.to===id),other:'from'}] : [])
    ] : [{label:'Incident',records:rows.filter(e=>e.from===id || e.to===id),other:null}];
    if(!groups.length)return ['No relationships recorded for this selection.'];
    return groups.flatMap(g=>{
      const a=summarize(g.records,id);
      if(!a.records)return [`No ${g.label.toLowerCase()} observations in the current filters.`];
      return [`${g.label}${D.signed ? ' net' : ''} total: ${amount(a.value)}`,
        ...(D.signed ? [`Sum of absolute flows: ${amount(a.magnitude)}`] : []),`${a.status} · ${a.known} of ${a.records} rows available`,
        ...g.records.map(e=>`${name(g.other ? e[g.other] : e.from===id ? e.to : e.from)}: ${amount(e.weight)}${e.provenance ? ' · '+e.provenance : ''}`)];
    });
  }
  function captureFocus() {
    const el=document.activeElement;
    for(const key of ['node','area','rank','inset-node','inset-area'])if(el?.hasAttribute?.(`data-${key}`))return {key,value:el.getAttribute(`data-${key}`)};
    return null;
  }
  function restoreFocus(saved) {
    if(!saved)return;
    const el=[...document.querySelectorAll(`[data-${saved.key}]`)].find(n=>n.getAttribute(`data-${saved.key}`)===saved.value);
    el?.focus({preventScroll:true});
  }
  const searchText=s=>s.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLocaleLowerCase();
  function filterSearch() {
    const query=searchText(state.query.trim());
    const matches=new Set(entities.filter(n=>searchText(n.label+' '+n.id).includes(query)).map(n=>n.id));
    $('entity-list').querySelectorAll('[data-entity]').forEach(n=>n.hidden=!matches.has(n.dataset.entity));
    $('ranking').querySelectorAll('[data-rank]').forEach(n=>n.hidden=!matches.has(n.dataset.rank));
    text('search-status',query ? `${matches.size} ${entityNames} match. Search narrows the lists, not the map.` : 'Search by name or code. Map filters stay unchanged.');
  }
  function focusDescription() {
    if(state.selected.size===entities.length)return `All ${entityNames}`;
    if(!state.selected.size)return `No ${entityNames} selected`;
    return [...state.selected].map(name).sort((a,b)=>a.localeCompare(b)).join(', ');
  }
  function layerDescription() {
    const enabled=layers.filter(l=>state.layers.has(l));
    if(enabled.length===1 && enabled[0]==='Relationships')return 'All supplied relationships';
    return !enabled.length ? 'No relationship layers enabled' : enabled.length===1 ? enabled[0]+' only' : enabled.join(' + ');
  }
  function viewCaptions() {
    return [
      ...(state.year ? [`Year ${state.year}`] : []),
      ...(D.directed ? [`Source: ${state.source ? name(state.source) : 'All sources'}`] : []),
      ...(edges.length ? [`Relationships: ${layerDescription()}`] : []),
      ...(areaMode && variables.length ? [`Variable: ${variables[state.variable].label}`] : []),
      `Focus: ${focusDescription()}`,
      ...(D.view ? [`Region: ${D.view.title}`] : []),
      ...(D.inset && state.inset ? [`Inset: ${D.inset.title} (west ${D.inset.west}°, south ${D.inset.south}°, east ${D.inset.east}°, north ${D.inset.north}°)`] : []),
      ...(D.background ? [`Background: ${state.background ? 'Illustrated context' : 'Plain network'}`] : [])
    ];
  }
  function legendNote() {
    if(legendOptions.note!==undefined && legendOptions.note!==null)return legendOptions.note;
    const insetNote=state.inset ? ' The purple rectangle marks the inset extent. Both maps use the same symbol and color scales.' : '';
    if(categoryMode())return 'Each category has a fixed color across periods. Legend counts cover the full map. Select a country for details.'+insetNote;
    if(areaMode)return `Fixed intervals${D.units ? ' in '+D.units : ''}. Gray means an unavailable observation or no dataset match; details distinguish the two. Orange outlines mark the focus.`+insetNote;
    return (state.size==='equal' ? 'Equal node sizes. ' : D.weighted ? `Circle area represents ${D.signed ? 'the sum of absolute incoming flows' : 'incoming total'}, using one scale across years and sources. ` : 'Circle area increases with distinct partners across the full enabled-layer network. ')+
      (D.signed ? 'Solid teal lines are positive; dashed amber lines are negative. Line width increases with absolute flow. Arrows retain the supplied direction. Totals retain signs. ' : D.weighted ? 'Line width increases with flow. ' : '')+
      'Orange outer rings mark the focus without changing the data symbols.'+insetNote;
  }
  function legendEntries() {
    if(areaMode && variables.length) {
      const variable=variables[state.variable];
      const labels=legendOptions.labels?.[variable.source_column],missing=legendOptions.missing_label || 'Unavailable or unmatched';
      if(variable.type==='categorical')return variable.categories.map((category,i)=>({kind:'fill',label:(labels?.[i] ?? category)+(legendOptions.show_counts===false ? '' : ` (${areas.filter(a=>a[variable.key]===category).length})`),color:variable.colors[i]}))
        .concat(areas.some(a=>a[variable.key]===null) ? [{kind:'fill',label:missing,color:'#d8dbd7'}] : []);
      const bs=variables[state.variable].breaks;
      return [`<${number(bs[0])}`,...bs.slice(0,-1).map((b,i)=>`${number(b)} to <${number(bs[i+1])}`),`\u2265${number(bs.at(-1))}`]
        .map((label,i)=>({kind:'fill',label:labels?.[i] ?? label,color:(variables[state.variable].colors || fills)[i]})).concat([{kind:'fill',label:missing,color:'#d8dbd7'}]);
    }
    const entries=[];
    if(state.layers.size) {
      if(D.signed)entries.push({kind:'line',label:'Positive flow',color:colors[0],dash:''},{kind:'line',label:'Negative flow',color:colors[1],dash:'7 4'});
      else if(layers.length>1) layers.forEach((l,i)=>{if(state.layers.has(l))entries.push({kind:'line',label:l,color:colors[i%colors.length],dash:['','7 4','2 4'][i%3]});});
      else if(D.directed) sources.forEach((id,i)=>{if(!state.source || state.source===id)entries.push({kind:'line',label:name(id),color:colors[i%colors.length],dash:['','7 4','2 4'][i%3]});});
      else if(layers.length)entries.push({kind:'line',label:layers[0],color:colors[0],dash:''});
    }
    if(D.weighted) {
      entries.push({kind:'circle',label:D.signed ? 'Nonzero flow magnitude' : 'Positive value',r:8,color:'#176f70'},
        {kind:'circle',label:D.signed ? 'All available flows zero' : 'Recorded zero',r:7,color:'#fafbf7',stroke:'#406f72'},
        {kind:'square',label:'Unavailable / no observation'},
        {kind:'circle',label:'Partial total',r:10,color:'#176f70',stroke:'#406f72',dash:'3 2'});
      if(D.directed && nodes.some(n=>sources.includes(n.id) && !targets.includes(n.id)))entries.push({kind:'diamond',label:'Source only'});
      if(state.size==='metric') [sizeMax/16,sizeMax/4,sizeMax].forEach(value=>entries.push({kind:'size',r:Math.sqrt(value/sizeMax*784),label:amount(value),color:'#176f70'}));
    }
    return entries;
  }
  function legendSymbol(entry) {
    const g=svg('g');
    if(entry.kind==='line')g.append(svg('line',{x1:8,y1:32,x2:66,y2:32,stroke:entry.color,'stroke-width':3,'stroke-dasharray':entry.dash}));
    else if(entry.kind==='fill')g.append(svg('rect',{x:24,y:20,width:26,height:24,fill:entry.color,stroke:'#b8c6be'}));
    else if(entry.kind==='square')g.append(svg('rect',{x:30,y:26,width:12,height:12,fill:'#fafbf7',stroke:'#687d7e','stroke-width':2}));
    else if(entry.kind==='diamond')g.append(svg('path',{d:'M36 23L45 32L36 41L27 32Z',fill:'#176f70',stroke:'#fff'}));
    else g.append(svg('circle',{cx:36,cy:32,r:entry.r,fill:entry.color,stroke:entry.stroke || '#fff','stroke-width':2,'stroke-dasharray':entry.dash || ''}));
    return g;
  }
  function renderLegend() {
    text('view-caption',viewCaptions().join(' · '));text('legend-note',legendNote());
    $('legend-items').replaceChildren();
    legendEntries().forEach(entry=>{
      const item=document.createElement('div');item.className='legend-item';
      const icon=svg('svg',{viewBox:'0 0 76 64',width:76,height:64,'aria-hidden':'true'});icon.append(legendSymbol(entry));
      const label=document.createElement('span');label.textContent=entry.label;item.append(icon,label);$('legend-items').append(item);
    });
  }
  function wrappedText(parent,value,x,y,width=112,size=14) {
    // Split long tokens too, so arbitrary labels do not overrun an exported figure.
    const words=String(value).split(/\s+/).flatMap(w=>w.match(new RegExp(`.{1,${width}}`,'gu')) || []);
    let line='';
    function emit(){parent.append(svg('text',{x,y,fill:'#203d42','font-family':'system-ui,sans-serif','font-size':size},line));y+=size+6;}
    for(const word of words){if(line && (line+' '+word).length>width){emit();line='';}line+=(line?' ':'')+word;}
    if(line)emit();
    return y;
  }
  function appendFigureNotes(figure, figureHeight=mapHeight) {
    const notes=svg('g',{'data-export-caption':'true'});let y=figureHeight+30;
    y=wrappedText(notes,D.title,30,y,88,18);
    for(const caption of viewCaptions())y=wrappedText(notes,caption,30,y);
    if(legendOptions.visible!==false) {
      if(legendOptions.title)y=wrappedText(notes,legendOptions.title,30,y,100,16);
      y=wrappedText(notes,legendNote(),30,y)+10;
      const entries=legendEntries(),columns=legendOptions.columns || 3,width=940/columns;
      for(let start=0;start<entries.length;start+=columns) {
        let bottom=y+70;
        for(let i=start;i<Math.min(start+columns,entries.length);i++) {
          const x=30+(i-start)*width;
          const icon=legendSymbol(entries[i]);icon.setAttribute('transform',`translate(${x} ${y})`);notes.append(icon);
          bottom=Math.max(bottom,wrappedText(notes,entries[i].label,x+80,y+28,Math.floor((width-90)/8),13)+10);
        }
        y=bottom+14;
      }
    }
    y+=16;
    y=wrappedText(notes,D.coordinates==='schematic' ? 'Schematic layout.' : 'Present-day boundaries.',30,y);
    if(D.notice)y=wrappedText(notes,D.notice,30,y);
    if(D.sources[0])y=wrappedText(notes,D.sources[0],30,y,122,12);
    const height=y+14;
    figure.append(svg('rect',{x:0,y:figureHeight,width:1000,height:height-figureHeight,fill:'#fafbf7'}),notes);
    return height;
  }
  function nodeRadius(rows,n) {
    if(state.size==='equal')return 8;
    if(!D.weighted)return Math.sqrt(36+degree(rows,n.id)*40);
    const value=sizeValue(incoming(rows,n.id));return value>0 ? Math.sqrt(value/sizeMax*784) : 7;
  }
  function draw(rows, shown) {
    const map = $('map'); map.replaceChildren();map.setAttribute('viewBox',`0 0 1000 ${mapHeight}`);
    map.append(svg('title',{},D.title));map.append(svg('desc',{},[D.description,D.notice,...D.sources].join('\n')));
    map.append(svg('rect',{width:1000,height:mapHeight,fill:'#fafbf7'}));
    const defs = svg('defs'), clip = svg('clipPath',{id:'viewport-clip'});
    clip.append(svg('rect',{x:0,y:0,width:1000,height:mapHeight})); defs.append(clip);
    const worldClip = svg('clipPath',{id:'world-clip'}); worldClip.append(svg('rect',{x:30,y:0,width:940,height:650})); defs.append(worldClip);
    colors.forEach((c,i) => { const m=svg('marker',{id:`arrow-${i}`,viewBox:'0 0 10 10',refX:9,refY:5,markerWidth:5,markerHeight:5,orient:'auto-start-reverse'}); m.append(svg('path',{d:'M0 0L10 5L0 10Z',fill:c})); defs.append(m); });
    map.append(defs);
    const viewport = svg('g',{'clip-path':'url(#viewport-clip)'}), scene=svg('g',{id:'scene',transform:`translate(${state.dx} ${state.dy}) scale(${state.zoom})`});
    viewport.append(scene); map.append(viewport);
    scene.append(svg('rect',{width:1000,height:mapHeight,fill:'#fafbf7'}));
    if (state.background && D.background) {
      const background = svg('g',{id:'illustration','pointer-events':'none'});
      const parsed = new DOMParser().parseFromString(`<svg xmlns="${NS}">${D.background}</svg>`,'image/svg+xml');
      [...parsed.documentElement.children].forEach(c => background.append(document.importNode(c,true)));
      scene.append(background);
    }
    const geo = svg('g',{id:'areas'});
    for (const a of areas) {
      const p=svg('path',{d:a.path,fill:areaColor(a),stroke:areaMode && state.selected.size < entities.length && state.selected.has(a.id) ? '#b45d32' : '#ffffff',
        'stroke-width':areaMode && state.selected.size < entities.length && state.selected.has(a.id) ? 1.8 : .6,'fill-rule':'evenodd',...(D.view ? {'vector-effect':'non-scaling-stroke'} : {}),'data-area':a.id});
      p.append(svg('title',{},a.label+(variables.length ? '\n'+areaValue(a,variables[state.variable])+' '+D.units : '')+(a.notes ? '\n'+a.notes : '')));
      if (areaMode) bindButton(p,a.id);
      geo.append(p);
    }
    scene.append(geo);
    const edgeGroup=svg('g',{id:'edges',...(D.coordinates === 'geographic' ? {'clip-path':'url(#world-clip)'} : {})});
    scene.append(edgeGroup);
    const shownSet=new Set(shown), near=new Set(shown.flatMap(e => [e.from,e.to])); state.selected.forEach(id => near.add(id));
    const radius=n=>nodeRadius(rows,n);
    for (const e of rows) {
      if (e.weight === null || e.weight === 0) continue;
      const a=nodeById.get(e.from), b=nodeById.get(e.to), color=lineColor(e);
      let bx=b.x; const wrapped=D.coordinates === 'geographic' && Math.abs(b.x-a.x)>470;
      if (wrapped) bx += b.x > a.x ? -940 : 940;
      const dx=bx-a.x,dy=b.y-a.y,len=Math.hypot(dx,dy)||1;
      const start=[a.x+dx/len*(radius(a)+2)/symbolScale,a.y+dy/len*(radius(a)+2)/symbolScale];
      const end=[bx-dx/len*(radius(b)+4)/symbolScale,b.y-dy/len*(radius(b)+4)/symbolScale];
      const offset=layers.length > 1 ? (layers.indexOf(e.layer)-.5)*22 : Math.min(40,len*.12);
      const cx=(a.x+bx)/2-dy/len*offset, cy=(a.y+b.y)/2+dx/len*offset;
      const shifts=wrapped ? [-940,0,940] : [0];
      for (const shift of shifts) {
        const p=svg('path',{d:`M${start[0]+shift} ${start[1]}Q${cx+shift} ${cy} ${end[0]+shift} ${end[1]}`,
          fill:'none',stroke:color,'stroke-width':(D.weighted ? 1+Math.sqrt(Math.abs(e.weight)/edgeMax)*3 : 2)/symbolScale,
          'stroke-dasharray':lineDash(e) ? lineDash(e).split(' ').map(n=>Number(n)/symbolScale).join(' ') : '',opacity:shownSet.has(e) ? .78 : .08,'data-edge':'true','data-from':e.from,'data-to':e.to,'data-weight':e.weight,'data-edge-layer':e.layer,'data-shift':shift,
          ...(D.directed ? {'marker-end':`url(#arrow-${colors.indexOf(color)})`} : {})});
        p.append(svg('title',{},`${name(e.from)} ${D.directed ? '→' : '↔'} ${name(e.to)} · ${e.layer}${D.weighted ? ' · '+amount(e.weight) : ''}`)); edgeGroup.append(p);
      }
    }
    const nodeGroup=svg('g',{id:'nodes'});scene.append(nodeGroup);
    const labels=[];
    for (const n of nodes) {
      const incomingValue=incoming(rows,n.id), r=radius(n), sourceOnly=D.directed && sources.includes(n.id) && !targets.includes(n.id);
      const inactiveSource=sourceOnly && state.source && n.id!==state.source;
      const g=svg('g',{transform:`translate(${n.x} ${n.y}) scale(${1/symbolScale})`,'data-node':n.id,opacity:inactiveSource ? .25 : near.has(n.id) ? 1 : .25});
      const selected=state.selected.size < nodes.length && state.selected.has(n.id);
      const base={fill:D.weighted && sizeValue(incomingValue) === 0 ? '#fafbf7' : '#176f70',stroke:'#ffffff','stroke-width':2};
      if (sourceOnly) g.append(svg('path',{d:'M0-9L9 0L0 9L-9 0Z',fill:colors[sources.indexOf(n.id)%colors.length],stroke:'#fff','stroke-width':2}));
      else if (D.weighted && incomingValue.value === null) g.append(svg('rect',{x:-6,y:-6,width:12,height:12,fill:'#fafbf7',stroke:'#687d7e','stroke-width':2}));
      else g.append(svg('circle',{r,...base,...(D.weighted && (incomingValue.partial || sizeValue(incomingValue)===0) ? {stroke:'#406f72','stroke-dasharray':incomingValue.partial ? '3 2' : '', 'stroke-width':2} : {})}));
      if(selected) g.append(svg('circle',{r:sourceOnly ? 14 : r+5,fill:'none',stroke:'#ae6038','stroke-width':2.5,'data-selection-ring':'true','pointer-events':'none'}));
      const label=svg('text',{x:0,y:-r-7,'text-anchor':'middle',fill:'#203d42','font-family':'system-ui,sans-serif','font-size':D.coordinates==='schematic' ? 13 : 11,
        'font-weight':600,'paint-order':'stroke',stroke:'#fafbf7','stroke-width':3,'stroke-linejoin':'round'},n.label);
      g.append(label); const info=sourceOnly ? outgoing(rows,n.id) : incomingValue;
      g.append(svg('title',{},`${n.label} · ${D.weighted ? (sourceOnly ? 'Outgoing' : 'Incoming')+' · '+info.status+' · '+amount(info.value) : degree(rows,n.id)+' distinct partners'}`));
      bindButton(g,n.id); nodeGroup.append(g);
      labels.push({n,r,label,g});
    }
    if(D.coordinates==='geographic') {
      // Place labels without changing geographic node coordinates.
      const occupied=labels.map(({n,r})=>({x:n.x-(r+2)/symbolScale,y:n.y-(r+2)/symbolScale,width:(2*r+4)/symbolScale,height:(2*r+4)/symbolScale}));
      const overlaps=(a,b)=>a.x<b.x+b.width+2 && a.x+a.width+2>b.x && a.y<b.y+b.height+2 && a.y+a.height+2>b.y;
      for(const {n,r,label,g} of labels) {
        let chosen;
        const candidates=[[0,-r-7,'middle'],[r+8,4,'start'],[-r-8,4,'end'],[0,r+18,'middle']];
        for(const offset of [22,38,54])candidates.push([0,-r-offset,'middle'],[r+8,-offset,'start'],[-r-8,-offset,'end'],[0,r+offset,'middle']);
        for(const [x,y,anchor] of candidates) {
          label.setAttribute('x',x);label.setAttribute('y',y);label.setAttribute('text-anchor',anchor);
          const box=label.getBBox(),b={x:n.x+box.x/symbolScale,y:n.y+box.y/symbolScale,width:box.width/symbolScale,height:box.height/symbolScale};
          if(b.x>=4 && b.x+b.width<=996 && b.y>=4 && b.y+b.height<=mapHeight-4 && !occupied.some(o=>overlaps(b,o))) {chosen=b;break;}
        }
        if(chosen)occupied.push(chosen);
        else {label.setAttribute('x',0);label.setAttribute('y',-r-7);label.setAttribute('text-anchor','middle');}
        const lx=Number(label.getAttribute('x')),ly=Number(label.getAttribute('y'));
        if(Math.hypot(lx,ly)>r+24)g.insertBefore(svg('line',{x1:0,y1:0,x2:lx,y2:ly+3,stroke:'#8a9a92','stroke-width':.6,'pointer-events':'none'}),g.firstChild);
      }
    }
  }
  function drawInset() {
    $('inset-panel').hidden=!state.inset;
    const inset=$('inset-map');inset.replaceChildren();
    if(!D.inset || !state.inset)return;
    const b=D.inset, west=30+(b.west+180)/360*940,east=30+(b.east+180)/360*940;
    const north=92+(85-b.north)/145*380,south=92+(85-b.south)/145*380;
    const width=east-west,height=south-north,h=Math.min(600,Math.max(240,1000*height/width));
    const scale=Math.min(1000/width,h/height),left=(1000-width*scale)/2,top=(h-height*scale)/2;
    inset.setAttribute('viewBox',`0 0 1000 ${h}`);inset.setAttribute('aria-label',b.title);
    text('inset-title',b.title);inset.append(svg('title',{},b.title),svg('rect',{width:1000,height:h,fill:'#fafbf7'}));
    const defs=$('map').querySelector('defs').cloneNode(true),clip=svg('clipPath',{id:'inset-region-clip'});
    clip.append(svg('rect',{x:left,y:top,width:width*scale,height:height*scale}));
    // Local IDs keep both SVGs independently valid, including figure exports.
    const ids=new Map([...defs.querySelectorAll('[id]')].map(el=>[el.id,'detail-'+el.id]));
    defs.querySelectorAll('[id]').forEach(el=>el.id=ids.get(el.id));defs.append(clip);inset.append(defs);
    const viewport=svg('g',{'clip-path':'url(#inset-region-clip)'}),scene=svg('g',{transform:`translate(${left-west*scale} ${top-north*scale}) scale(${scale})`});
    viewport.append(scene);inset.append(viewport);
    const inside=n=>n && n.longitude>=b.west && n.longitude<=b.east && n.latitude>=b.south && n.latitude<=b.north;
    const rows=active();
    for(const id of ['areas','edges','nodes']) {
      const group=$(id).cloneNode(true);group.id='inset-'+id;
      group.querySelectorAll('[id]').forEach(el=>el.removeAttribute('id'));
      if(id==='edges')group.querySelectorAll('[data-edge]').forEach(el=>{
        const a=nodeById.get(el.dataset.from),endNode=nodeById.get(el.dataset.to);
        if(!inside(a) && !inside(endNode)){el.remove();return;}
        // Recompute endpoint padding for the constant-size inset symbols.
        let bx=endNode.x;if(Math.abs(bx-a.x)>470)bx+=bx>a.x ? -940 : 940;
        const dx=bx-a.x,dy=endNode.y-a.y,len=Math.hypot(dx,dy)||1;
        const ar=(nodeRadius(rows,a)+2)/scale,br=(nodeRadius(rows,endNode)+4)/scale;
        const offset=layers.length>1 ? (layers.indexOf(el.dataset.edgeLayer)-.5)*22 : Math.min(40,len*.12);
        const cx=(a.x+bx)/2-dy/len*offset,cy=(a.y+endNode.y)/2+dx/len*offset,shift=Number(el.dataset.shift);
        el.setAttribute('d',`M${a.x+dx/len*ar+shift} ${a.y+dy/len*ar}Q${cx+shift} ${cy} ${bx-dx/len*br+shift} ${endNode.y-dy/len*br}`);
      });
      if(id==='nodes')group.querySelectorAll('[data-node]').forEach(el=>{
        const n=nodeById.get(el.dataset.node);if(!inside(n)){el.remove();return;}
        el.setAttribute('transform',`translate(${n.x} ${n.y}) scale(${1/scale})`);
        el.querySelectorAll('text').forEach(label=>label.setAttribute('font-size','14'));
        el.removeAttribute('data-node');el.setAttribute('data-inset-node',n.id);
        bindButton(el,n.id);el.addEventListener('click',()=>toggle(n.id));
      });
      if(id==='areas')group.querySelectorAll('[data-area]').forEach(el=>{
        const key=el.dataset.area;el.removeAttribute('data-area');el.setAttribute('data-inset-area',key);
        if(areaMode){
          const original=[...$('areas').children].find(a=>a.dataset.area===key),box=original.getBBox();
          if(box.x>east || box.x+box.width<west || box.y>south || box.y+box.height<north){el.remove();return;}
          bindButton(el,key);el.addEventListener('click',()=>toggle(key));
        }
      });
      // Scale geometry while preserving point, line, and arrow sizes on the page.
      if(id!=='nodes')group.querySelectorAll('[stroke-width]').forEach(el=>el.setAttribute('stroke-width',Number(el.getAttribute('stroke-width'))*(id==='edges' ? symbolScale : 1)/scale));
      if(id==='edges')group.querySelectorAll('[stroke-dasharray]').forEach(el=>{
        const dash=el.getAttribute('stroke-dasharray');if(dash)el.setAttribute('stroke-dasharray',dash.split(' ').map(n=>Number(n)*symbolScale/scale).join(' '));
      });
      [group,...group.querySelectorAll('*')].forEach(el=>{
        for(const attr of ['clip-path','marker-end']) {
          const value=el.getAttribute(attr);if(value)el.setAttribute(attr,value.replace(/url\(#([^)]+)\)/g,(_,key)=>`url(#${ids.get(key)||key})`));
        }
      });
      scene.append(group);
    }
    $('scene').insertBefore(svg('rect',{x:west,y:north,width,height,fill:'none',stroke:'#71558a','stroke-width':1.5,
      'stroke-dasharray':'5 3','pointer-events':'none','data-inset-extent':'true'}),$('edges'));
  }
  function makeCell(tr,value,id=null) {
    const td=document.createElement('td');
    if (id!==null) { const b=document.createElement('button');b.textContent=value;b.onclick=() => toggle(id);td.append(b); }
    else td.textContent=value;
    tr.append(td);
  }
  function updateTable(rows,shown) {
    let columns,records;
    if (areaMode) {
      const notes=areas.some(a=>a.notes!==undefined);
      columns=['Area',variables[state.variable]?.label || 'Value','Status',...(notes ? ['Notes'] : [])];
      records=areas.filter(a => state.selected.has(a.id)).map(a => [a.label,areaValue(a,variables[state.variable]),areaStatus(a,variables[state.variable]),...(notes ? [a.notes || ''] : [])]);
      text('table-title','Area observations');
    } else {
      const provenance=edges.some(e=>e.provenance);
      columns=['From','To','Relationship',...(D.weighted ? ['Value'+(D.units ? ' ('+D.units+')' : ''),'Status'] : []),...(provenance ? ['Reporting provenance'] : [])];
      records=shown.map(e => [name(e.from),name(e.to),e.layer,...(D.weighted ? [number(e.weight),e.status] : []),...(provenance ? [e.provenance || ''] : [])]);
      text('table-title','Relationship register');
    }
    const head=document.createElement('tr');columns.forEach(c => {const th=document.createElement('th');th.scope='col';th.textContent=c;head.append(th);});$('table-head').replaceChildren(head);
    $('rows').replaceChildren();
    records.forEach(record => { const tr=document.createElement('tr');record.forEach(value => makeCell(tr,value));$('rows').append(tr); });
    if (!records.length) {const tr=document.createElement('tr'),td=document.createElement('td');td.colSpan=columns.length;td.textContent='No observations in this selection.';tr.append(td);$('rows').append(tr);}
    text('table-summary',`${records.length} rows`);
  }
  function render() {
    const focusKey=captureFocus();
    applyAreaFrame();
    const rows=active(), shown=focusRows(rows), ks=known(rows);
    $('year').value=state.year || ''; $('source').value=state.source; $('variable').value=String(state.variable);
    text('focus-summary',focusName());text('map-title',areaMode ? 'Across geographic areas' : D.coordinates==='schematic' ? 'A network of relationships' : 'Places and flows');
    text('metric-label',areaMode ? 'Areas with data' : D.weighted ? `Known ${D.signed ? 'net ' : ''}total in current filters` : 'Unique pairs in focus');
    text('metric',areaMode ? `${areas.filter(a => a[variables[state.variable]?.key] != null).length} / ${areas.length}` : D.weighted ? amount(total(rows)) : distinctPairs(shown));
    text('coverage-label',areaMode ? 'Variable' : D.weighted ? 'Observed rows' : 'Layer-specific ties in focus');
    text('coverage',areaMode ? variables[state.variable]?.label || 'None' : D.weighted ? `${ks.length} / ${rows.length}${ks.length<rows.length ? ' · partial' : ''}` : shown.length);
    text('detail-title',focusName());
    text('detail',areaMode ? categoryMode() ? `Select a ${entityName} to inspect its category and notes for this period.` : `Select a ${entityName} to inspect its values. Gray means unavailable or unmatched, never zero.` : D.weighted ? `Select a ${entityName} to inspect its flows. Source and year filters set the overall total; focus highlights incident relationships.` : `Select ${entityNames} to explore their combined ties. Distinct partners count multiple relationship types to the same ${entityName} once.`);
    $('detail-values').replaceChildren();
    if (state.selected.size===1) {
      const id=[...state.selected][0];
      const entries=areaMode ? [...variables.map(v => `${v.label}: ${areaValue(byId.get(id),v)} ${D.units} · ${areaStatus(byId.get(id),v)}`),...(byId.get(id).notes ? [byId.get(id).notes] : [])] : D.weighted ? flowDetails(rows,id) : [`${degree(rows,id)} distinct partners`,`${shown.length} layer-specific ties`];
      entries.forEach(s => {const p=document.createElement('p');p.textContent=s;$('detail-values').append(p);});
    }
    if(state.selected.size>1 && state.selected.size<entities.length) {const p=document.createElement('p');p.textContent=[...state.selected].map(name).join(', ');$('detail-values').append(p);}
    $('entity-list').querySelectorAll('input').forEach(i => i.checked=state.selected.has(i.value));
    $('layers').querySelectorAll('input').forEach(i => i.checked=state.layers.has(i.value));
    text('ranking-title',areaMode ? categoryMode() ? 'Countries by category' : 'Values by area' : D.weighted ? `${D.signed ? 'Net incoming' : 'Incoming'} totals` : 'Distinct partners');
    let ranked=entities.map(n => ({...n,value:areaMode ? n[variables[state.variable]?.key] : D.weighted ? incoming(rows,n.id).value : degree(rows,n.id)}));
    if (D.weighted && D.directed) ranked=ranked.filter(n => targets.includes(n.id));
    ranked.sort((a,b) => (categoryMode() ? variables[state.variable].categories.indexOf(a.value)-variables[state.variable].categories.indexOf(b.value) : (b.value ?? -Infinity)-(a.value ?? -Infinity)) || a.label.localeCompare(b.label));
    const diverging=!categoryMode() && ranked.some(n=>n.value<0),max=categoryMode() ? 1 : Math.max(1,...ranked.map(n => Math.abs(n.value || 0)));$('ranking').replaceChildren();
    ranked.forEach(n => {const b=document.createElement('button');b.className='rank'+(categoryMode() ? ' category-rank' : '');b.dataset.rank=n.id;b.setAttribute('aria-label',`${n.label}, ${categoryMode() ? n.value ?? 'Unavailable' : number(n.value)}. Toggle selection.`);b.setAttribute('aria-pressed',String(state.selected.has(n.id)));
      const label=document.createElement('span');label.className='rank-name';label.textContent=n.label;
      const track=document.createElement('span');track.className='track'+(diverging ? ' diverging' : '');const fill=document.createElement('span');
      fill.style.width=categoryMode() ? '100%' : `${Math.abs(n.value||0)/max*(diverging ? 50 : 100)}%`;
      if(categoryMode())fill.style.background=areaColor(n);
      if(diverging){fill.style.position='absolute';fill.style[n.value<0 ? 'right' : 'left']='50%';fill.style.background=n.value<0 ? colors[1] : colors[0];}track.append(fill);
      const value=document.createElement('span');value.textContent=categoryMode() ? n.value ?? 'Unavailable' : short(n.value);b.append(label,track,value);b.onclick=() => toggle(n.id);$('ranking').append(b);});
    if(years.length){$('previous-period').disabled=state.year===years[0];$('next-period').disabled=state.year===years.at(-1);}
    updateTable(rows,shown);draw(rows,shown);drawInset();renderLegend();renderTrend();filterSearch();restoreFocus(focusKey);
  }
  function countryHistory() {
    if(!areaMode || categoryMode() || !variables.length || areaFrames.length<2 || state.selected.size!==1)return [];
    const id=[...state.selected][0],v=variables[state.variable];
    return [...areaFrames].sort((a,b)=>a.time.localeCompare(b.time,undefined,{numeric:true})).map(frame=>{
      const row=frame.data.find(a=>a.id===id);
      return {time:frame.time,value:row?.[v.key] ?? null,status:row ? areaStatus(row,v) : 'No observation',notes:row?.notes || ''};
    });
  }
  function renderTrend() {
    const history=countryHistory(),panel=$('trend-panel'),chart=$('trend-chart');
    panel.hidden=!history.length || !controlVisible('history');chart.replaceChildren();$('trend-rows').replaceChildren();
    if(panel.hidden)return;
    const label=name([...state.selected][0]),v=variables[state.variable];
    text('trend-title',`${label} over time`);
    const current=history.find(row=>row.time===state.year);
    text('trend-current',`${state.year}: ${amount(current?.value ?? null)}`);
    text('trend-note',`Scale fits this country's full history and stays fixed during playback. Gaps mean missing observations. Values are in ${D.units || 'the supplied units'}.`);
    chart.setAttribute('aria-label',`${label}, ${v.label}, ${history[0].time} to ${history.at(-1).time}. ${$('trend-note').textContent}`);
    chart.append(svg('title',{},chart.getAttribute('aria-label')));
    const values=history.filter(row=>row.value!==null).map(row=>row.value);
    const low=Math.min(0,...values),high=Math.max(0,...values),span=high-low || 1;
    const numericTimes=history.map(row=>Number(row.time)),continuous=numericTimes.every(Number.isFinite) && new Set(numericTimes).size===history.length;
    const first=continuous ? numericTimes[0] : 0,last=continuous ? numericTimes.at(-1) : history.length-1;
    const x=i=>58+((continuous ? numericTimes[i] : i)-first)/(last-first || 1)*226;
    const y=value=>164-(value-low)/span*138;
    const labelText=(tx,ty,value,anchor='start')=>svg('text',{x:tx,y:ty,fill:'#203d42','font-family':'system-ui,sans-serif','font-size':12,'text-anchor':anchor},value);
    for(const value of [...new Set([low,0,high])]) {
      chart.append(svg('line',{x1:58,x2:284,y1:y(value),y2:y(value),stroke:value===0 ? '#738784' : '#d9e1dc','stroke-dasharray':value===0 ? '' : '3 3','data-trend-zero':value===0 ? 'true' : 'false'}),labelText(52,y(value)+4,short(value),'end'));
    }
    chart.append(labelText(58,190,history[0].time),labelText(284,190,history.at(-1).time,'end'));
    let segment=[];
    const flush=()=>{if(segment.length>1)chart.append(svg('polyline',{points:segment.join(' '),fill:'none',stroke:'#176f70','stroke-width':2,'data-trend-segment':'true'}));segment=[];};
    history.forEach((row,i)=>{if(row.value===null)flush();else segment.push(`${x(i)},${y(row.value)}`);});flush();
    history.forEach((row,i)=>{
      if(row.value!==null){const dot=svg('circle',{cx:x(i),cy:y(row.value),r:2.5,fill:row.value<0 ? '#a9602d' : '#176f70','data-trend-time':row.time,'data-trend-value':row.value});dot.append(svg('title',{},`${row.time}: ${amount(row.value)}`));chart.append(dot);}
      if(row.time===state.year){chart.append(svg('line',{x1:x(i),x2:x(i),y1:20,y2:168,stroke:'#be872c','stroke-dasharray':'4 3','data-trend-current':row.time}));if(row.value!==null)chart.append(svg('circle',{cx:x(i),cy:y(row.value),r:5,fill:'none',stroke:'#be872c','stroke-width':2}));}
      const tr=document.createElement('tr');[row.time,amount(row.value),[row.status,row.notes].filter(Boolean).join('. ')].forEach(value=>makeCell(tr,value));$('trend-rows').append(tr);
    });
    if(!values.length)chart.append(labelText(170,92,'No available observations','middle'));
  }
  text('title',D.title);text('description',D.description);text('notice',D.notice);$('notice').hidden=!D.notice;
  text('kind',areaMode ? 'VARIABLES ACROSS AREAS' : D.coordinates==='schematic' ? 'A SCHEMATIC NETWORK' : 'A GEOGRAPHIC NETWORK');
  text('map-eyebrow',areaMode ? 'COMPARE THE VALUES' : 'EXPLORE THE CONNECTIONS');
  text('map-note',areaMode ? `Color shows the selected variable. Search ${entityNames} to inspect small areas. Drag anywhere on the map to pan.` : D.coordinates==='schematic' ? `Click or use Enter to select ${entityNames}. Drag nodes to rearrange them. Drag the empty background to pan. The illustration is schematic.` : 'Click a node to inspect it. Arrows show relationships, not transport routes. Drag the background to pan. Zoom does not change geographic locations.');
  text('table-note',areaMode ? 'The table and CSV follow the current selection and variable. All data JSON contains the complete embedded area table.' : 'Rows follow the year, source, layers, and selected endpoints. Zero and unavailable values remain distinct. All data JSON contains the complete embedded dataset.');
  D.sources.forEach(s => {const p=document.createElement('p');p.textContent=s;$('sources').append(p);});
  const coverageNote=document.createElement('p');coverageNote.textContent=D.coverage==='complete_panel' ? 'Complete panel checked at build time. Every source-target-time-layer observation must have a row; unknown values remain unavailable.' : D.coverage==='observed_rows' ? 'Observed-row coverage. Absent rows are not converted to zero.' : D.coverage==='edge_list' ? 'Edge-list coverage. Ties describe the supplied network only; an absent tie does not establish historical absence.' : 'Values are embedded at export time. Missing or unmatched areas are not imputed.';$('sources').append(coverageNote);
  if (years.length) { $('time-control').hidden=false;years.forEach(y => option($('year'),y,y)); }
  if(years.length>1)$('period-controls').hidden=false;
  let playback=null;
  function stopPlayback(){if(playback!==null)clearInterval(playback);playback=null;text('play-periods',controlLabel('play','Play'));$('play-periods').setAttribute('aria-pressed','false');}
  function stepPeriod(delta){stopPlayback();state.year=years[Math.max(0,Math.min(years.length-1,years.indexOf(state.year)+delta))];render();}
  $('previous-period').onclick=()=>stepPeriod(-1);$('next-period').onclick=()=>stepPeriod(1);
  $('play-periods').onclick=()=>{
    if(playback!==null){stopPlayback();return;}
    if(state.year===years.at(-1)){state.year=years[0];render();}
    text('play-periods',controlLabel('pause','Pause'));$('play-periods').setAttribute('aria-pressed','true');
    playback=setInterval(()=>{state.year=years[years.indexOf(state.year)+1];render();if(state.year===years.at(-1))stopPlayback();},controlOptions.playback_interval || 1400);
  };
  document.addEventListener('visibilitychange',()=>{if(document.hidden)stopPlayback();});
  if (D.directed && sources.length) { $('source-control').hidden=false;option($('source'),'','All sources');sources.forEach(id => option($('source'),id,name(id))); }
  if (variables.length) { $('variable-control').hidden=false;variables.forEach((v,i) => option($('variable'),String(i),v.label)); }
  if (layers.length>1) { $('layer-control').hidden=false; layers.forEach((layer,i) => {const label=document.createElement('label'),input=document.createElement('input');input.type='checkbox';input.value=layer;input.checked=true;input.dataset.layer=layer;input.onchange=() => {input.checked ? state.layers.add(layer) : state.layers.delete(layer);render();};label.append(input,document.createTextNode(layer));$('layers').append(label);}); }
  if (nodes.length) { $('size-control').hidden=false;$('size').options[0].textContent=D.weighted ? D.signed ? 'Absolute incoming flows' : 'Incoming total' : 'Distinct partners'; }
  if (D.background) $('background-control').hidden=false;
  if(D.inset){$('inset-control').hidden=false;$('inset-toggle').value=state.inset ? 'show' : 'hide';}
  $('inset-toggle').onchange=()=>{state.inset=$('inset-toggle').value==='show';render();};
  [...entities].sort((a,b) => a.label.localeCompare(b.label)).forEach(n => {const label=document.createElement('label'),input=document.createElement('input');input.type='checkbox';input.value=n.id;input.checked=true;label.dataset.entity=n.id;input.onchange=() => {input.checked ? state.selected.add(n.id) : state.selected.delete(n.id);render();};label.append(input,document.createTextNode(n.label));$('entity-list').append(label);});
  text('picker-label',`Choose ${entityNames}`);text('search-label',`Find ${entityNames}`);
  $('entity-search').oninput=() => {state.query=$('entity-search').value;if(state.query)$('picker').open=true;filterSearch();};
  $('clear-focus').onclick=() => {state.selected=new Set(entities.map(n=>n.id));render();};
  $('year').onchange=() => {stopPlayback();state.year=$('year').value;render();};
  $('source').onchange=() => {state.source=$('source').value;render();};
  $('variable').onchange=() => {state.variable=Number($('variable').value);render();};
  $('size').onchange=() => {state.size=$('size').value;render();};
  $('background').onchange=() => {state.background=$('background').value==='show';render();};
  $('select-all').onclick=() => {state.selected=new Set(entities.map(n => n.id));render();};
  $('clear-selection').onclick=() => {state.selected.clear();render();};
  function camera() { const scene=$('scene');if (scene) scene.setAttribute('transform',`translate(${state.dx} ${state.dy}) scale(${state.zoom})`); }
  function zoom(factor) { const z=Math.max(baseCamera.zoom,Math.min(baseCamera.zoom*4,state.zoom*factor));state.dx=500-(500-state.dx)*z/state.zoom;state.dy=mapHeight/2-(mapHeight/2-state.dy)*z/state.zoom;state.zoom=z;camera(); }
  $('zoom-in').onclick=() => zoom(1.25);$('zoom-out').onclick=() => zoom(.8);
  $('zoom-reset').onclick=() => {Object.assign(state,baseCamera);camera();};
  $('reset').onclick=() => {stopPlayback();state.year=initial.year;state.source=initial.source;state.selected=new Set(entities.map(n => n.id));state.layers=new Set(layers);state.variable=0;state.size='metric';state.background=true;state.inset=D.inset?.visible ?? false;$('inset-toggle').value=state.inset ? 'show' : 'hide';Object.assign(state,baseCamera);state.query='';$('entity-search').value='';nodes.forEach((n,i) => Object.assign(n,D.nodes[i]));$('size').value='metric';$('background').value='show';$('picker').open=false;render();};
  let drag=null;
  const point=e => new DOMPoint(e.clientX,e.clientY).matrixTransform($('map').getScreenCTM().inverse());
  $('map').addEventListener('pointerdown',e => {
    if(e.button!==0)return;
    const node=e.target.closest('[data-node]'),area=e.target.closest('[data-area]'),p=point(e);
    drag={id:node?.dataset.node || null,area:areaMode ? area?.dataset.area : null,clientX:e.clientX,clientY:e.clientY,last:p,moved:false};
    $('map').setPointerCapture(e.pointerId);
    if(node || (area && areaMode)) (node || area).focus({preventScroll:true}); else $('map').focus({preventScroll:true});
    e.preventDefault();
  });
  $('map').addEventListener('pointermove',e => {
    if(!drag)return;const p=point(e);
    if(Math.hypot(e.clientX-drag.clientX,e.clientY-drag.clientY)>5)drag.moved=true;
    if(!drag.moved)return;
    if(drag.id && D.coordinates==='schematic' && D.controls.drag) {
      const n=nodeById.get(drag.id);n.x=Math.max(30,Math.min(970,(p.x-state.dx)/state.zoom));
      n.y=Math.max(30,Math.min(600,(p.y-state.dy)/state.zoom));render();
    } else {state.dx+=p.x-drag.last.x;state.dy+=p.y-drag.last.y;camera();}
    drag.last=p;
  });
  $('map').addEventListener('pointerup',() => {if(!drag)return;const d=drag;drag=null;if(!d.moved && (d.id || d.area))toggle(d.id || d.area);});
  $('map').addEventListener('pointercancel',() => drag=null);
  $('map').addEventListener('keydown',e => {
    const delta={ArrowLeft:[40,0],ArrowRight:[-40,0],ArrowUp:[0,40],ArrowDown:[0,-40]}[e.key];
    if(delta){e.preventDefault();state.dx+=delta[0];state.dy+=delta[1];camera();}
  });
  const filename=D.title.toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'') || 'atlas';
  function download(blob,suffix) {const url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download=filename+suffix;a.click();setTimeout(() => URL.revokeObjectURL(url),30000);text('download-status','Prepared '+a.download+' from embedded data.');}
  function svgText() {
    stopPlayback();
    const clone=$('map').cloneNode(true);clone.setAttribute('xmlns',NS);
    let figureHeight=mapHeight;
    if(D.inset && state.inset) {
      const inset=$('inset-map').cloneNode(true),h=inset.viewBox.baseVal.height;
      clone.append(svg('text',{x:30,y:mapHeight+26,fill:'#203d42','font-family':'system-ui,sans-serif','font-size':18},D.inset.title));
      inset.setAttribute('x','0');inset.setAttribute('y',String(mapHeight+42));inset.setAttribute('width','1000');inset.setAttribute('height',String(h));
      inset.setAttribute('data-export-inset','true');clone.append(inset);figureHeight=mapHeight+42+h+16;
    }
    if(!$('trend-panel').hidden) {
      clone.append(svg('text',{x:30,y:figureHeight+28,fill:'#203d42','font-family':'system-ui,sans-serif','font-size':18},$('trend-title').textContent));
      const trend=$('trend-chart').cloneNode(true);trend.setAttribute('x','30');trend.setAttribute('y',String(figureHeight+40));trend.setAttribute('width','450');trend.setAttribute('height','315');trend.setAttribute('data-export-trend','true');clone.append(trend);
      clone.append(svg('text',{x:500,y:figureHeight+90,fill:'#203d42','font-family':'system-ui,sans-serif','font-size':14},$('trend-current').textContent));
      ['Scale fits this country’s full history.','Gaps mean missing observations.',`Units: ${D.units || 'supplied units'}`].forEach((line,i)=>clone.append(svg('text',{x:500,y:figureHeight+125+i*22,fill:'#5d7073','font-family':'system-ui,sans-serif','font-size':13},line)));
      figureHeight+=370;
    }
    const height=appendFigureNotes(clone,figureHeight);
    clone.insertBefore(svg('rect',{width:1000,height,fill:'#fafbf7','data-export-background':'true'}),clone.firstChild);
    clone.setAttribute('viewBox',`0 0 1000 ${height}`);clone.setAttribute('width','1600');clone.setAttribute('height',String(height*1.6));
    clone.removeAttribute('tabindex');
    clone.querySelectorAll('[tabindex],[role]').forEach(n => {n.removeAttribute('tabindex');n.removeAttribute('role');});
    return {text:new XMLSerializer().serializeToString(clone),height};
  }
  $('export-svg').onclick=() => download(new Blob([svgText().text],{type:'image/svg+xml'}),'.svg');
  $('export-png').onclick=() => {const figure=svgText(),image=new Image(),url=URL.createObjectURL(new Blob([figure.text],{type:'image/svg+xml'}));image.onload=() => {const canvas=document.createElement('canvas');canvas.width=2000;canvas.height=figure.height*2;canvas.getContext('2d').drawImage(image,0,0,2000,figure.height*2);URL.revokeObjectURL(url);canvas.toBlob(blob => {if(blob)download(blob,'.png');else text('download-status','PNG could not be created. Save SVG instead.');},'image/png');};image.onerror=() => {URL.revokeObjectURL(url);text('download-status','PNG could not be created. Save SVG instead.');};image.src=url;};
  function csvCell(v) {let s=v===null || v===undefined ? 'NA' : String(v);if(typeof v==='string' && /^[=+\-@\t\r]/.test(s))s="'"+s;return '"'+s.replaceAll('"','""')+'"';}
  $('export-history').onclick=()=>{
    stopPlayback();const history=countryHistory();if(!history.length)return;
    const id=[...state.selected][0],header=['id','label','time','variable','value','status','notes','units','notice','sources'];
    const records=history.map(row=>[id,name(id),row.time,variables[state.variable].label,row.value,row.status,row.notes,D.units,D.notice,D.sources.join(' | ')]);
    download(new Blob([[header,...records].map(row=>row.map(csvCell).join(',')).join('\r\n')+'\r\n'],{type:'text/csv;charset=utf-8'}),'-history.csv');
  };
  $('export-csv').onclick=() => {
    stopPlayback();
    let header,records;
    if(areaMode) {const v=variables[state.variable],timed=areaFrames.length>0,notes=areas.some(a=>a.notes!==undefined);header=['id','label','variable','value','status',...(timed ? ['time'] : []),...(notes ? ['notes'] : []),'units','notice','sources'];records=areas.filter(a => state.selected.has(a.id)).map(a => [a.id,a.label,v?.label || '',v ? a[v.key] : null,areaStatus(a,v),...(timed ? [state.year] : []),...(notes ? [a.notes || ''] : []),D.units,D.notice,D.sources.join(' | ')]);}
    else {const provenance=edges.some(e=>e.provenance);header=['from','to','layer','time','weight','status',...(provenance ? ['provenance'] : []),'units','notice','sources'];records=focusRows(active()).map(e => [e.from,e.to,e.layer,e.time,e.weight,e.status,...(provenance ? [e.provenance || ''] : []),D.units,D.notice,D.sources.join(' | ')]);}
    const csv=[header,...records].map(row => row.map(csvCell).join(',')).join('\r\n')+'\r\n';download(new Blob([csv],{type:'text/csv;charset=utf-8'}),'.csv');
  };
  $('export-json').onclick=() => {stopPlayback();download(new Blob([JSON.stringify(D,null,2)],{type:'application/json'}),'.json');};
  // Read-only diagnostics for reproducible semantic and browser checks.
  window.offlineAtlas={snapshot:() => {const rows=active(),shown=focusRows(rows);return {title:D.title,year:state.year,source:state.source,selected:[...state.selected],layers:[...state.layers],nodeCount:nodes.length,
    edgeCount:edges.length,activeRows:rows.length,shownRows:shown.length,uniquePairs:distinctPairs(shown),knownRows:known(rows).length,total:total(rows),
    degree:Object.fromEntries(nodes.map(n => [n.id,degree(rows,n.id)])),incoming:Object.fromEntries(nodes.map(n => [n.id,incoming(rows,n.id)])),positions:nodes.map(n => ({id:n.id,x:n.x,y:n.y})),
    variable:variables[state.variable]?.source_column || null,inset:state.inset,areaCount:areas.length,
    ...(areaFrames.length ? {areaValues:Object.fromEntries(areas.map(a=>[a.id,a[variables[state.variable]?.key]]))} : {}),
    areasWithData:areas.filter(a => a[variables[state.variable]?.key] != null).length};}};
  function configurePresentation() {
    if (["compact", "presentation"].includes(D.preset)) document.body.classList.add("preset-" + D.preset);
    document.body.style.fontFamily=uiFont;
    document.querySelectorAll('h1,h2,.stats strong').forEach(el=>el.style.fontFamily=fontStacks[D.style?.heading_family] || fontStacks.serif);
    const legend=$('legend'),toolbar=document.querySelector('.toolbar'),notebook=document.querySelector('.notebook');
    legend.hidden=legendOptions.visible===false;
    legend.querySelector('h3').textContent=legendOptions.title || 'Reading this view';
    if(legendOptions.columns)$('legend-items').style.gridTemplateColumns=`repeat(${legendOptions.columns},minmax(0,1fr))`;
    if(legendOptions.position==='above')$('map').before(legend);
    if(legendOptions.position==='sidebar'){notebook.append(legend);legend.classList.add('sidebar-legend');}
    if(controlOptions.position==='above_map')$('map').before(toolbar);
    if(controlOptions.position==='sidebar'){notebook.prepend(toolbar);toolbar.classList.add('sidebar-controls');}
    const groups={time:'time-control',playback:'period-controls',source:'source-control',variable:'variable-control',layers:'layer-control',size:'size-control',background:'background-control',inset:'inset-control',reset:'reset',zoom:'.zoom',search:'entity-search',selection:'picker',downloads:'.downloads'};
    for(const [key,id] of Object.entries(groups))if(!controlVisible(key)) {
      (id.startsWith('.') ? document.querySelector(id) : $(id)).hidden=true;
      if(key==='search'){$('search-label').hidden=true;$('search-status').hidden=true;}
      if(key==='selection')$('clear-focus').hidden=true;
    }
    $('export-history').hidden=!controlVisible('downloads');
    toolbar.hidden=[...toolbar.children].every(el=>el.hidden);
    const buttons={previous:'previous-period',play:'play-periods',next:'next-period',reset:'reset',zoom_in:'zoom-in',zoom_out:'zoom-out',fit:'zoom-reset',clear_focus:'clear-focus',select_all:'select-all',select_none:'clear-selection',export_svg:'export-svg',export_png:'export-png',export_csv:'export-csv',export_json:'export-json',history_csv:'export-history',search:'search-label',selection:'picker-label'};
    for(const [key,id] of Object.entries(buttons))if(controlOptions.labels?.[key]) {
      text(id,controlOptions.labels[key]);if($(id).hasAttribute('aria-label'))$(id).setAttribute('aria-label',controlOptions.labels[key]);
    }
    for(const key of ['time','source','variable','size','background','inset'])if(controlOptions.labels?.[key])$(groups[key]).firstChild.textContent=controlOptions.labels[key];
    if(controlOptions.labels?.layers)$('layer-control').querySelector('legend').textContent=controlOptions.labels.layers;
  }
  configurePresentation();render();
})();
