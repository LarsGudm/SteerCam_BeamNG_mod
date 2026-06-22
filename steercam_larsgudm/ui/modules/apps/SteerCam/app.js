angular.module('beamng.apps')
.directive('steerCam', [function () {
  return {
    template: [
      '<div class="steerCamApp">',
        '<style>',
          '.steerCamApp{font-family:"Segoe UI",sans-serif;color:#e8e8ea;background:rgba(18,18,20,0.88);position:relative;',
            'border-radius:7px;padding:9px 11px;box-sizing:border-box;width:100%;height:100%;overflow:auto;font-size:12px}',
          '.steerCamApp .sc-title{font-weight:700;font-size:14px;letter-spacing:.5px;color:#ff7a18}',
          '.steerCamApp .sc-title-row{display:flex;align-items:center;justify-content:space-between;margin-bottom:6px}',
          '.steerCamApp .sc-mod-en{display:flex;align-items:center;gap:5px;font-size:11px;font-weight:600;color:#9a9aa0;cursor:pointer}',
          '.steerCamApp .sc-mod-en input{accent-color:#ff7a18;margin:0}',
          '.steerCamApp .sc-mirror{display:flex;align-items:center;gap:7px;margin:0 0 8px;font-size:11px;color:#cfcfd4;cursor:pointer}',
          '.steerCamApp .sc-mirror input{accent-color:#ff7a18;margin:0}',
          '.steerCamApp .sc-presets{display:flex;gap:5px;margin-bottom:8px}',
          '.steerCamApp .sc-presets button{flex:1 1 0;background:rgba(255,255,255,0.08);color:#e8e8ea;border:1px solid rgba(255,255,255,0.14);',
            'border-radius:4px;padding:4px 6px;font-size:11px;cursor:pointer}',
          '.steerCamApp .sc-presets button:hover{background:rgba(255,255,255,0.16)}',
          '.steerCamApp .sc-presets button.active{background:#ff7a18;border-color:#ff7a18;color:#161616;font-weight:700}',
          '.steerCamApp .sc-glance-btns{display:flex;gap:5px;margin:7px 0 2px}',
          '.steerCamApp .sc-glance-btns button{flex:1 1 0;background:rgba(255,255,255,0.08);color:#e8e8ea;',
            'border:1px solid rgba(255,255,255,0.14);border-radius:4px;padding:5px 6px;font-size:11px;cursor:pointer}',
          '.steerCamApp .sc-glance-btns button:hover{background:rgba(255,255,255,0.16)}',
          '.steerCamApp .sc-glance-btns button.active{background:#ff7a18;border-color:#ff7a18;color:#161616;font-weight:700}',
          '.steerCamApp .sc-sec{font-weight:600;margin:4px 0 5px;color:#ffae6b;',
            'border-bottom:1px solid rgba(255,255,255,0.12);padding-bottom:2px}',
          '.steerCamApp .sc-row{display:flex;align-items:center;gap:7px;margin:5px 0}',
          '.steerCamApp .sc-row>span{flex:0 0 84px;white-space:nowrap}',
          '.steerCamApp .sc-row input[type=range]{flex:1 1 auto;min-width:34px;accent-color:#ff7a18}',
          '.steerCamApp .sc-presets-row{display:flex;align-items:center;gap:7px;margin-bottom:8px}',
          '.steerCamApp .sc-presets-lbl{flex:0 0 auto;font-weight:700;font-size:12px;color:#ff7a18}',
          '.steerCamApp .sc-dd{position:relative;flex:1 1 auto}',
          '.steerCamApp .sc-dd-head{width:100%;display:flex;justify-content:space-between;align-items:center;',
            'background:rgba(255,255,255,0.08);color:#e8e8ea;border:1px solid rgba(255,255,255,0.14);',
            'border-radius:4px;padding:4px 7px;font-size:11px;cursor:pointer}',
          '.steerCamApp .sc-dd-head:hover{background:rgba(255,255,255,0.16)}',
          '.steerCamApp .sc-dd-arr{color:#ff7a18;font-size:9px;margin-left:6px}',
          '.steerCamApp .sc-dd-list{position:absolute;top:100%;left:0;right:0;z-index:20;',
            'background:rgba(28,28,32,0.98);border:1px solid rgba(255,255,255,0.18);border-radius:4px;overflow:hidden}',
          '.steerCamApp .sc-dd-opt{display:flex;align-items:center;gap:6px;padding:5px 7px;font-size:11px;cursor:pointer}',
          '.steerCamApp .sc-dd-opt:hover{background:rgba(255,255,255,0.12)}',
          '.steerCamApp .sc-dd-opt.active{background:#ff7a18;color:#161616;font-weight:700}',
          '.steerCamApp .sc-row>b{flex:0 0 42px;text-align:right;color:#fff;font-variant-numeric:tabular-nums}',
          '.steerCamApp .sc-chk label{display:flex;align-items:center;gap:7px;cursor:pointer}',
          '.steerCamApp .sc-chk input{accent-color:#ff7a18}',
          '.steerCamApp.locked .sc-row{opacity:0.5}',
          '.steerCamApp.locked .sc-chk label{cursor:default}',
          '.steerCamApp .sc-row.sc-dim{opacity:0.45}',
          '.steerCamApp .sc-sec .sc-en{display:flex;align-items:center;justify-content:space-between}',
          '.steerCamApp .sc-sec .sc-en input{accent-color:#ff7a18;margin:0}',
          '.steerCamApp .sc-sec-name{display:flex;align-items:center;gap:6px;flex:1 1 auto;cursor:pointer;user-select:none}',
          '.steerCamApp .sc-tw{display:inline-block;font-size:9px;color:#ff7a18;transition:transform .15s ease}',
          '.steerCamApp .sc-tw.open{transform:rotate(90deg)}',
          '.steerCamApp .sc-off{opacity:0.4;pointer-events:none}',
          // dim a disabled section's header text without blocking its collapse click
          '.steerCamApp .sc-sec-name.sc-dim{opacity:0.4}',
          '.steerCamApp .sc-hint{font-size:10px;color:#9a9aa0;margin-top:6px}',
          '.steerCamApp .sc-tipsrc{display:none}',
          // small ⓘ marker appended (dynamically, via ng-if) to anything with a tooltip
          '.steerCamApp .sc-info{margin-left:3px;font-size:10px;color:#ff7a18;opacity:0.7;cursor:help}',
          // hover bubble lives on <body> (escapes the panel overflow), so this rule
          // is intentionally NOT scoped under .steerCamApp:
          '.sc-bubble{position:fixed;z-index:99999;max-width:240px;background:#fff;color:#111;',
            'font-size:13px;line-height:1.32;padding:6px 9px;border-radius:5px;',
            'box-shadow:0 3px 12px rgba(0,0,0,0.45);pointer-events:none;display:none}',
          // preset dropdown rows: name (clickable) + protected lock + delete-x; plus
          // a separator and the "save as new" action item at the bottom of the list
          '.steerCamApp .sc-dd-name{flex:1 1 auto;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}',
          '.steerCamApp .sc-lock{flex:0 0 auto;font-size:10px;opacity:0.7;filter:grayscale(1)}',   // monochrome padlock
          '.steerCamApp .sc-del-x{flex:0 0 auto;font-size:14px;line-height:1;opacity:0.5;cursor:pointer}',
          '.steerCamApp .sc-del-x:hover{opacity:1;color:#ff8a8a}',
          '.steerCamApp .sc-dd-sep{height:1px;background:rgba(255,255,255,0.15);margin:3px 0}',
          '.steerCamApp .sc-dd-save{color:#ffae6b}',
          '.steerCamApp .sc-dd-save:hover{background:rgba(255,122,24,0.18)}',
          // current-selection text in the dropdown head + the "(modified)" tag + Reset
          '.steerCamApp .sc-dd-cur{flex:1 1 auto;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;text-align:left}',
          '.steerCamApp .sc-mod-tag{color:#ffae6b;font-size:10px}',
          '.steerCamApp .sc-reset-btn{flex:0 0 auto;background:rgba(255,255,255,0.08);color:#ffae6b;',
            'border:1px solid rgba(255,255,255,0.14);border-radius:4px;padding:4px 9px;font-size:11px;cursor:pointer}',
          '.steerCamApp .sc-reset-btn:hover{background:rgba(255,255,255,0.16)}',
          // red confirm button for destructive actions (delete)
          '.steerCamApp .sc-confirm-btns .yes.danger{background:#c0392b;border-color:#c0392b;color:#fff}',
          // text input reused by the save-as / overwrite modal
          '.steerCamApp .sc-preset-name{width:100%;box-sizing:border-box;margin:0 0 10px;background:rgba(255,255,255,0.08);',
            'color:#e8e8ea;border:1px solid rgba(255,255,255,0.14);border-radius:4px;padding:5px 7px;font-size:12px}',
          '.steerCamApp .sc-preset-name::placeholder{color:#7a7a80}',
          // in-panel confirm overlay (overwrite / delete)
          '.steerCamApp .sc-confirm{position:absolute;inset:0;z-index:200;display:flex;align-items:center;',
            'justify-content:center;background:rgba(0,0,0,0.55);border-radius:7px}',
          '.steerCamApp .sc-confirm-box{background:#1c1c20;border:1px solid rgba(255,255,255,0.2);',
            'border-radius:6px;padding:12px 14px;max-width:240px;text-align:center}',
          '.steerCamApp .sc-confirm-text{font-size:12px;color:#e8e8ea;margin-bottom:10px;line-height:1.35}',
          '.steerCamApp .sc-confirm-btns{display:flex;gap:7px;justify-content:center}',
          '.steerCamApp .sc-confirm-btns button{background:rgba(255,255,255,0.08);color:#e8e8ea;',
            'border:1px solid rgba(255,255,255,0.14);border-radius:4px;padding:4px 12px;font-size:11px;cursor:pointer}',
          '.steerCamApp .sc-confirm-btns .yes{background:#ff7a18;border-color:#ff7a18;color:#161616;font-weight:700}',
          // header: gear (Settings) + Enabled, on the right of the title row
          '.steerCamApp .sc-hdr-right{display:flex;align-items:center;gap:8px}',
          '.steerCamApp .sc-gear{background:none;border:none;color:#ffae6b;font-size:15px;line-height:1;cursor:pointer;padding:0}',
          '.steerCamApp .sc-gear:hover{color:#ff7a18}',
          // settings overlay (darkens the panel)
          '.steerCamApp .sc-settings{position:absolute;inset:0;z-index:300;display:flex;align-items:center;',
            'justify-content:center;background:rgba(0,0,0,0.62);border-radius:7px}',
          '.steerCamApp .sc-settings-box{background:#1c1c20;border:1px solid rgba(255,255,255,0.2);',
            'border-radius:6px;padding:12px 14px;box-sizing:border-box;width:calc(100% - 100px)}',  // 50px each side
          '.steerCamApp .sc-set-close{width:100%;margin-top:12px;background:#ff7a18;border:1px solid #ff7a18;',
            'color:#161616;font-weight:700;border-radius:4px;padding:5px 0;font-size:12px;cursor:pointer}',
          '.steerCamApp .sc-set-close:hover{background:#ff8c33}',
          '.steerCamApp .sc-settings-hd{display:flex;justify-content:space-between;align-items:center;',
            'font-weight:700;color:#ff7a18;font-size:13px;margin-bottom:8px}',
          '.steerCamApp .sc-settings-x{cursor:pointer;font-size:17px;line-height:1;opacity:0.7;color:#e8e8ea}',
          '.steerCamApp .sc-settings-x:hover{opacity:1}',
          '.steerCamApp .sc-set-chk{display:flex;align-items:center;gap:7px;font-size:11px;color:#cfcfd4;cursor:pointer;margin:9px 0 0}',
          '.steerCamApp .sc-set-chk input{accent-color:#ff7a18;margin:0}',
          '.steerCamApp .sc-set-note{font-size:10px;color:#9a9aa0;margin:3px 0 4px 22px}',
          '.steerCamApp .sc-set-ver{font-size:10px;color:#7a7a80;border-top:1px solid rgba(255,255,255,0.12);',
            'margin-top:10px;padding-top:8px;text-align:center}',
        '</style>',

        '<div class="sc-title-row">',
          '<span class="sc-title">SteerCam</span>',
          '<div class="sc-hdr-right">',
            '<button class="sc-gear" ng-click="openSettings()" title="Settings">&#9881;&#65038;</button>',
            '<label class="sc-mod-en"><input type="checkbox" ng-model="modEnabled" ng-change="setMod(modEnabled)"><span>Enabled</span><span class="sc-tipsrc" ng-if="tips.modEnable">{{tips.modEnable}}</span><span class="sc-info" ng-if="tips.modEnable">&#9432;</span></label>',
          '</div>',
        '</div>',

        '<div class="sc-presets-row">',
          '<span class="sc-presets-lbl">Presets</span>',
          '<div class="sc-dd" ng-mouseleave="openDD=null">',
            '<button class="sc-dd-head" ng-click="toggleDD(\'preset\')"><span class="sc-dd-cur">{{preset}}<span class="sc-mod-tag" ng-if="modified"> (modified)</span></span><span class="sc-dd-arr">▾</span></button>',
            '<div class="sc-dd-list" ng-show="openDD===\'preset\'">',
              '<div class="sc-dd-opt" ng-repeat="p in presetNames" ng-class="{active: preset===p}" ng-click="choose(p); openDD=null">',
                '<span class="sc-dd-name">{{p}}</span>',
                '<span class="sc-lock" ng-if="protectedMap[p]">&#128274;&#65038;</span>',
                '<span class="sc-del-x" ng-if="canDelete(p)" ng-click="$event.stopPropagation(); askDeletePreset(p)" title="Delete preset">&#215;</span>',
              '</div>',
              '<div class="sc-dd-sep"></div>',
              '<div class="sc-dd-opt sc-dd-save" ng-if="canSaveChanges()" ng-click="saveChanges()">&#10003; Save changes to this preset</div>',
              '<div class="sc-dd-opt sc-dd-save" ng-click="saveAsNew()">+ Save as new preset…</div>',
              '<div class="sc-dd-opt sc-dd-save" ng-click="openPresetFolder()">Open preset folder…</div>',
            '</div>',
          '</div>',
          '<button class="sc-reset-btn" ng-if="modified" ng-click="resetChanges()" title="Discard changes (back to the saved preset)">Reset</button>',
        '</div>',

        '<div class="sc-sec"><div class="sc-en"><span class="sc-sec-name" ng-class="{\'sc-dim\':!cfg.camEnable}" ng-click="toggleCollapse(\'cam\')"><span class="sc-tw" ng-class="{open:!collapsed.cam}">▸</span>Camera settings override<span class="sc-tipsrc" ng-if="tips.cam">{{tips.cam}}</span><span class="sc-info" ng-if="tips.cam">&#9432;</span></span><input type="checkbox" ng-model="cfg.camEnable" ng-change="setEnable(\'cam\',\'camEnable\',cfg.camEnable)" ng-disabled="locked"></div></div>',
        '<div class="sc-sec-body" ng-show="!collapsed.cam" ng-class="{\'sc-off\':!cfg.camEnable}">',
          '<div class="sc-row"><span>Forward Offset<span class="sc-tipsrc" ng-if="tips.camFwd">{{tips.camFwd}}</span><span class="sc-info" ng-if="tips.camFwd">&#9432;</span></span>',
            '<input type="range" min="-0.5" max="0.5" step="0.01" ng-model="cfg.camFwd" ng-change="set(\'camFwd\', cfg.camFwd)" ng-disabled="locked">',
            '<b>{{cfg.camFwd}}m</b></div>',
          '<div class="sc-row"><span>Vertical Offset<span class="sc-tipsrc" ng-if="tips.camUp">{{tips.camUp}}</span><span class="sc-info" ng-if="tips.camUp">&#9432;</span></span>',
            '<input type="range" min="-0.5" max="0.5" step="0.01" ng-model="cfg.camUp" ng-change="set(\'camUp\', cfg.camUp)" ng-disabled="locked">',
            '<b>{{cfg.camUp}}m</b></div>',
          '<div class="sc-row"><span>Rotate L/R<span class="sc-tipsrc" ng-if="tips.camYaw">{{tips.camYaw}}</span><span class="sc-info" ng-if="tips.camYaw">&#9432;</span></span>',
            '<input type="range" min="-45" max="45" step="1" ng-model="cfg.camYaw" ng-change="set(\'camYaw\', cfg.camYaw)" ng-disabled="locked">',
            '<b>{{cfg.camYaw}}°</b></div>',
          '<div class="sc-row"><span>Rotate D/U<span class="sc-tipsrc" ng-if="tips.camPitch">{{tips.camPitch}}</span><span class="sc-info" ng-if="tips.camPitch">&#9432;</span></span>',
            '<input type="range" min="-45" max="45" step="1" ng-model="cfg.camPitch" ng-change="set(\'camPitch\', cfg.camPitch)" ng-disabled="locked">',
            '<b>{{cfg.camPitch}}°</b></div>',
          '<div class="sc-row"><span>Horizon lock<span class="sc-tipsrc" ng-if="tips.stableHorizon">{{tips.stableHorizon}}</span><span class="sc-info" ng-if="tips.stableHorizon">&#9432;</span></span>',
            '<input type="range" min="0" max="100" step="1" ng-model="cfg.stableHorizon" ng-change="set(\'stableHorizon\', cfg.stableHorizon)" ng-disabled="locked">',
            '<b>{{cfg.stableHorizon}}%</b></div>',
          '<div class="sc-row"><span>FOV<span class="sc-tipsrc" ng-if="tips.camFov">{{tips.camFov}}</span><span class="sc-info" ng-if="tips.camFov">&#9432;</span></span>',
            '<input type="range" min="40" max="120" step="1" ng-model="cfg.camFov" ng-change="set(\'camFov\', cfg.camFov)" ng-disabled="locked">',
            '<b>{{cfg.camFov}}°</b></div>',
          '<div class="sc-row"><span>Near clip<span class="sc-tipsrc" ng-if="tips.nearClip">{{tips.nearClip}}</span><span class="sc-info" ng-if="tips.nearClip">&#9432;</span></span>',
            '<input type="range" min="0.01" max="0.1" step="0.01" ng-model="cfg.nearClip" ng-change="set(\'nearClip\', cfg.nearClip)" ng-disabled="locked">',
            '<b>{{cfg.nearClip}}m</b></div>',
        '</div>',

        '<div class="sc-sec"><div class="sc-en"><span class="sc-sec-name" ng-class="{\'sc-dim\':!cfg.steerEnable}" ng-click="toggleCollapse(\'steer\')"><span class="sc-tw" ng-class="{open:!collapsed.steer}">▸</span>Steering Input Pan<span class="sc-tipsrc" ng-if="tips.steer">{{tips.steer}}</span><span class="sc-info" ng-if="tips.steer">&#9432;</span></span><input type="checkbox" ng-model="cfg.steerEnable" ng-change="setEnable(\'steer\',\'steerEnable\',cfg.steerEnable)" ng-disabled="locked"></div></div>',
        '<div class="sc-sec-body" ng-show="!collapsed.steer" ng-class="{\'sc-off\':!cfg.steerEnable}">',
          '<div class="sc-row"><span>Angle<span class="sc-tipsrc" ng-if="tips.angle">{{tips.angle}}</span><span class="sc-info" ng-if="tips.angle">&#9432;</span></span>',
            '<input type="range" min="0" max="90" step="1" ng-model="cfg.angle" ng-change="set(\'angle\', cfg.angle)" ng-disabled="locked">',
            '<b>{{cfg.angle}}°</b></div>',
          '<div class="sc-row"><span>Steering range<span class="sc-tipsrc" ng-if="tips.reach">{{tips.reach}}</span><span class="sc-info" ng-if="tips.reach">&#9432;</span></span>',
            '<input type="range" min="10" max="100" step="5" ng-model="cfg.reach" ng-change="set(\'reach\', cfg.reach)" ng-disabled="locked">',
            '<b>{{cfg.reach}}%</b></div>',
          '<div class="sc-row"><span>Stiffness<span class="sc-tipsrc" ng-if="tips.stiffness">{{tips.stiffness}}</span><span class="sc-info" ng-if="tips.stiffness">&#9432;</span></span>',
            '<input type="range" min="1" max="40" step="1" ng-model="cfg.stiffness" ng-change="set(\'stiffness\', cfg.stiffness)" ng-disabled="locked">',
            '<b>{{cfg.stiffness}}</b></div>',
          '<div class="sc-row sc-chk"><label><input type="checkbox" ng-model="cfg.reverseSteer" ng-change="set(\'reverseSteer\', cfg.reverseSteer)" ng-disabled="locked"> Mirror turn direction when reversing<span class="sc-tipsrc" ng-if="tips.reverseSteer">{{tips.reverseSteer}}</span><span class="sc-info" ng-if="tips.reverseSteer">&#9432;</span></label></div>',
          '<div class="sc-row" ng-show="cfg.reverseSteer"><span>Reverse angle<span class="sc-tipsrc" ng-if="tips.reverseAngle">{{tips.reverseAngle}}</span><span class="sc-info" ng-if="tips.reverseAngle">&#9432;</span></span>',
            '<input type="range" min="0" max="90" step="1" ng-model="cfg.reverseAngle" ng-change="set(\'reverseAngle\', cfg.reverseAngle)" ng-disabled="locked">',
            '<b>{{cfg.reverseAngle}}°</b></div>',
          '<div class="sc-row" ng-show="cfg.reverseSteer"><span>Reverse blend<span class="sc-tipsrc" ng-if="tips.reverseTime">{{tips.reverseTime}}</span><span class="sc-info" ng-if="tips.reverseTime">&#9432;</span></span>',
            '<input type="range" min="0" max="3000" step="50" ng-model="cfg.reverseTime" ng-change="set(\'reverseTime\', cfg.reverseTime)" ng-disabled="locked">',
            '<b>{{cfg.reverseTime}}ms</b></div>',
          '<div class="sc-row sc-chk"><label><input type="checkbox" ng-model="cfg.speedFade" ng-change="set(\'speedFade\', cfg.speedFade)" ng-disabled="locked"> Fade in with speed<span class="sc-tipsrc" ng-if="tips.speedFade">{{tips.speedFade}}</span><span class="sc-info" ng-if="tips.speedFade">&#9432;</span></label></div>',
          '<div class="sc-row" ng-show="cfg.speedFade"><span>Fade speed<span class="sc-tipsrc" ng-if="tips.fadeSpeed">{{tips.fadeSpeed}}</span><span class="sc-info" ng-if="tips.fadeSpeed">&#9432;</span></span>',
            '<input type="range" min="5" max="150" step="5" ng-model="cfg.fadeSpeed" ng-change="set(\'fadeSpeed\', cfg.fadeSpeed)" ng-disabled="locked">',
            '<b style="flex:0 0 64px">{{cfg.fadeSpeed}} km/h</b></div>',
          '<div class="sc-row" ng-show="cfg.speedFade"><span>Standstill turn<span class="sc-tipsrc" ng-if="tips.fadeFloor">{{tips.fadeFloor}}</span><span class="sc-info" ng-if="tips.fadeFloor">&#9432;</span></span>',
            '<input type="range" min="0" max="100" step="5" ng-model="cfg.fadeFloor" ng-change="set(\'fadeFloor\', cfg.fadeFloor)" ng-disabled="locked">',
            '<b>{{cfg.fadeFloor}}%</b></div>',
        '</div>',

        '<div class="sc-sec"><div class="sc-en"><span class="sc-sec-name" ng-class="{\'sc-dim\':!cfg.glanceEnable}" ng-click="toggleCollapse(\'glance\')"><span class="sc-tw" ng-class="{open:!collapsed.glance}">▸</span>Blind-spot glance<span class="sc-tipsrc" ng-if="tips.glance">{{tips.glance}}</span><span class="sc-info" ng-if="tips.glance">&#9432;</span></span><input type="checkbox" ng-model="cfg.glanceEnable" ng-change="setEnable(\'glance\',\'glanceEnable\',cfg.glanceEnable)" ng-disabled="locked"></div></div>',
        '<div class="sc-sec-body" ng-show="!collapsed.glance" ng-class="{\'sc-off\':!cfg.glanceEnable}">',
          '<div class="sc-glance-btns">',
            '<button ng-class="{active: glanceSide===\'left\'}" ng-click="toggleGlance(\'left\')">Preview left</button>',
            '<button ng-class="{active: glanceSide===\'back\'}" ng-click="toggleGlance(\'back\')">Preview back</button>',
            '<button ng-class="{active: glanceSide===\'right\'}" ng-click="toggleGlance(\'right\')">Preview right</button>',
          '</div>',
          '<div class="sc-hint">Preview holds the glance so you can tune the angle. Needs the SteerCam view active (press C).</div>',
          '<div class="sc-row"><span>Left angle<span class="sc-tipsrc" ng-if="tips.glanceLeft">{{tips.glanceLeft}}</span><span class="sc-info" ng-if="tips.glanceLeft">&#9432;</span></span>',
            '<input type="range" min="0" max="170" step="1" ng-model="cfg.glanceLeft" ng-change="set(\'glanceLeft\', cfg.glanceLeft)" ng-disabled="locked">',
            '<b>{{cfg.glanceLeft}}°</b></div>',
          '<div class="sc-row"><span>Left offset<span class="sc-tipsrc" ng-if="tips.glanceOffsetLeft">{{tips.glanceOffsetLeft}}</span><span class="sc-info" ng-if="tips.glanceOffsetLeft">&#9432;</span></span>',
            '<input type="range" min="-0.5" max="0.5" step="0.01" ng-model="cfg.glanceOffsetLeft" ng-change="set(\'glanceOffsetLeft\', cfg.glanceOffsetLeft)" ng-disabled="locked">',
            '<b>{{cfg.glanceOffsetLeft}}m</b></div>',
          '<div class="sc-row"><span>Right angle<span class="sc-tipsrc" ng-if="tips.glanceRight">{{tips.glanceRight}}</span><span class="sc-info" ng-if="tips.glanceRight">&#9432;</span></span>',
            '<input type="range" min="0" max="170" step="1" ng-model="cfg.glanceRight" ng-change="set(\'glanceRight\', cfg.glanceRight)" ng-disabled="locked">',
            '<b>{{cfg.glanceRight}}°</b></div>',
          '<div class="sc-row"><span>Right offset<span class="sc-tipsrc" ng-if="tips.glanceOffsetRight">{{tips.glanceOffsetRight}}</span><span class="sc-info" ng-if="tips.glanceOffsetRight">&#9432;</span></span>',
            '<input type="range" min="-0.5" max="0.5" step="0.01" ng-model="cfg.glanceOffsetRight" ng-change="set(\'glanceOffsetRight\', cfg.glanceOffsetRight)" ng-disabled="locked">',
            '<b>{{cfg.glanceOffsetRight}}m</b></div>',
          '<div class="sc-row"><span>Back angle<span class="sc-tipsrc" ng-if="tips.glanceBack">{{tips.glanceBack}}</span><span class="sc-info" ng-if="tips.glanceBack">&#9432;</span></span>',
            '<input type="range" min="-90" max="90" step="1" ng-model="cfg.glanceBack" ng-change="set(\'glanceBack\', cfg.glanceBack)" ng-disabled="locked">',
            '<b>{{cfg.glanceBack}}°</b></div>',
          '<div class="sc-row"><span>Back offset<span class="sc-tipsrc" ng-if="tips.glanceOffsetBack">{{tips.glanceOffsetBack}}</span><span class="sc-info" ng-if="tips.glanceOffsetBack">&#9432;</span></span>',
            '<input type="range" min="-0.5" max="0.5" step="0.01" ng-model="cfg.glanceOffsetBack" ng-change="set(\'glanceOffsetBack\', cfg.glanceOffsetBack)" ng-disabled="locked">',
            '<b>{{cfg.glanceOffsetBack}}m</b></div>',
          '<div class="sc-row"><span>Back roll<span class="sc-tipsrc" ng-if="tips.glanceBackRoll">{{tips.glanceBackRoll}}</span><span class="sc-info" ng-if="tips.glanceBackRoll">&#9432;</span></span>',
            '<input type="range" min="-15" max="15" step="1" ng-model="cfg.glanceBackRoll" ng-change="set(\'glanceBackRoll\', cfg.glanceBackRoll)" ng-disabled="locked">',
            '<b>{{cfg.glanceBackRoll}}°</b></div>',
          '<div class="sc-row"><span>Glance transition<span class="sc-tipsrc" ng-if="tips.glanceTransition">{{tips.glanceTransition}}</span><span class="sc-info" ng-if="tips.glanceTransition">&#9432;</span></span>',
            '<div class="sc-dd" ng-mouseleave="openDD=null">',
              '<button class="sc-dd-head" ng-click="toggleDD(\'transition\')" ng-disabled="locked">{{transitionLabel(cfg.glanceTransition)}}<span class="sc-dd-arr">▾</span></button>',
              '<div class="sc-dd-list" ng-show="openDD===\'transition\'">',
                '<div class="sc-dd-opt" ng-repeat="o in transitionOptions" ng-class="{active: cfg.glanceTransition===o.k}" ng-click="setTransition(o.k); openDD=null">{{o.l}}</div>',
              '</div>',
            '</div></div>',
          '<div class="sc-row" ng-class="{\'sc-dim\':cfg.glanceTransition===\'None\'}"><span>Glance time<span class="sc-tipsrc" ng-if="tips.glanceTime">{{tips.glanceTime}}</span><span class="sc-info" ng-if="tips.glanceTime">&#9432;</span></span>',
            '<input type="range" min="0" max="500" step="10" ng-model="cfg.glanceTime" ng-change="set(\'glanceTime\', cfg.glanceTime)" ng-disabled="locked || cfg.glanceTransition===\'None\'">',
            '<b>{{cfg.glanceTime}}ms</b></div>',
          '<div class="sc-row" ng-class="{\'sc-dim\':cfg.glanceTransition===\'None\'}"><span>Glance curve<span class="sc-tipsrc" ng-if="tips.glanceCurve">{{tips.glanceCurve}}</span><span class="sc-info" ng-if="tips.glanceCurve">&#9432;</span></span>',
            '<div class="sc-dd" ng-mouseleave="openDD=null">',
              '<button class="sc-dd-head" ng-click="toggleDD(\'curve\')" ng-disabled="locked || cfg.glanceTransition===\'None\'">{{curveLabel(cfg.glanceCurve)}}<span class="sc-dd-arr">▾</span></button>',
              '<div class="sc-dd-list" ng-show="openDD===\'curve\'">',
                '<div class="sc-dd-opt" ng-repeat="o in curveOptions" ng-class="{active: cfg.glanceCurve===o.k}" ng-click="setCurve(o.k); openDD=null">{{o.l}}</div>',
              '</div>',
            '</div></div>',
        '</div>',

        '<div class="sc-sec"><div class="sc-en"><span class="sc-sec-name" ng-class="{\'sc-dim\':!cfg.speedModEnable}" ng-click="toggleCollapse(\'speed\')"><span class="sc-tw" ng-class="{open:!collapsed.speed}">▸</span>Immersive extras<span class="sc-tipsrc" ng-if="tips.speed">{{tips.speed}}</span><span class="sc-info" ng-if="tips.speed">&#9432;</span></span><input type="checkbox" ng-model="cfg.speedModEnable" ng-change="setEnable(\'speed\',\'speedModEnable\',cfg.speedModEnable)" ng-disabled="locked"></div></div>',
        '<div class="sc-sec-body" ng-show="!collapsed.speed" ng-class="{\'sc-off\':!cfg.speedModEnable}">',
          '<div class="sc-row sc-chk"><label><input type="checkbox" ng-model="cfg.vertigo" ng-change="set(\'vertigo\', cfg.vertigo)" ng-disabled="locked"> Speed vertigo (FOV)<span class="sc-tipsrc" ng-if="tips.vertigo">{{tips.vertigo}}</span><span class="sc-info" ng-if="tips.vertigo">&#9432;</span></label></div>',
          '<div class="sc-row" ng-class="{\'sc-dim\':!cfg.vertigo}"><span>FOV change<span class="sc-tipsrc" ng-if="tips.vertigoFov">{{tips.vertigoFov}}</span><span class="sc-info" ng-if="tips.vertigoFov">&#9432;</span></span>',
            '<input type="range" min="0" max="40" step="1" ng-model="cfg.vertigoFov" ng-change="set(\'vertigoFov\', cfg.vertigoFov)" ng-disabled="locked || !cfg.vertigo">',
            '<b>{{cfg.vertigoFov}}°</b></div>',
          '<div class="sc-row" ng-class="{\'sc-dim\':!cfg.vertigo}"><span>Dolly depth<span class="sc-tipsrc" ng-if="tips.vertigoDolly">{{tips.vertigoDolly}}</span><span class="sc-info" ng-if="tips.vertigoDolly">&#9432;</span></span>',
            '<input type="range" min="0" max="1.5" step="0.01" ng-model="cfg.vertigoDolly" ng-change="set(\'vertigoDolly\', cfg.vertigoDolly)" ng-disabled="locked || !cfg.vertigo">',
            '<b>{{cfg.vertigoDolly}}m</b></div>',
          '<div class="sc-row sc-chk"><label><input type="checkbox" ng-model="cfg.speedRoll" ng-change="set(\'speedRoll\', cfg.speedRoll)" ng-disabled="locked"> Speed camera roll<span class="sc-tipsrc" ng-if="tips.speedRoll">{{tips.speedRoll}}</span><span class="sc-info" ng-if="tips.speedRoll">&#9432;</span></label></div>',
          '<div class="sc-row" ng-class="{\'sc-dim\':!cfg.speedRoll}"><span>Roll change<span class="sc-tipsrc" ng-if="tips.rollAngle">{{tips.rollAngle}}</span><span class="sc-info" ng-if="tips.rollAngle">&#9432;</span></span>',
            '<input type="range" min="0" max="20" step="0.5" ng-model="cfg.rollAngle" ng-change="set(\'rollAngle\', cfg.rollAngle)" ng-disabled="locked || !cfg.speedRoll">',
            '<b>{{cfg.rollAngle}}°</b></div>',
          '<div class="sc-row" ng-class="{\'sc-dim\':!cfg.speedRoll}"><span>Roll source<span class="sc-tipsrc" ng-if="tips.rollSource">{{tips.rollSource}}</span><span class="sc-info" ng-if="tips.rollSource">&#9432;</span></span>',
            '<div class="sc-dd" ng-mouseleave="openDD=null">',
              '<button class="sc-dd-head" ng-click="toggleDD(\'rollSource\')" ng-disabled="locked || !cfg.speedRoll">{{rollSourceLabel(cfg.rollSource)}}<span class="sc-dd-arr">▾</span></button>',
              '<div class="sc-dd-list" ng-show="openDD===\'rollSource\'">',
                '<div class="sc-dd-opt" ng-repeat="o in rollSourceOptions" ng-class="{active: cfg.rollSource===o.k}" ng-click="setRollSource(o.k); openDD=null">{{o.l}}</div>',
              '</div>',
            '</div></div>',
          '<div class="sc-row"><span>Speed range<span class="sc-tipsrc" ng-if="tips.speedRange">{{tips.speedRange}}</span><span class="sc-info" ng-if="tips.speedRange">&#9432;</span></span>',
            '<input type="range" min="20" max="400" step="5" ng-model="cfg.speedRange" ng-change="set(\'speedRange\', cfg.speedRange)" ng-disabled="locked">',
            '<b style="flex:0 0 64px">{{cfg.speedRange}} km/h</b></div>',
          '<div class="sc-row sc-chk"><label><input type="checkbox" ng-model="cfg.vertInertia" ng-change="set(\'vertInertia\', cfg.vertInertia)" ng-disabled="locked"> Head lift (vertical inertia)<span class="sc-tipsrc" ng-if="tips.vertInertia">{{tips.vertInertia}}</span><span class="sc-info" ng-if="tips.vertInertia">&#9432;</span></label></div>',
          '<div class="sc-row" ng-class="{\'sc-dim\':!cfg.vertInertia}"><span>Max lift<span class="sc-tipsrc" ng-if="tips.vertInertiaMax">{{tips.vertInertiaMax}}</span><span class="sc-info" ng-if="tips.vertInertiaMax">&#9432;</span></span>',
            '<input type="range" min="0" max="30" step="0.5" ng-model="cfg.vertInertiaMax" ng-change="set(\'vertInertiaMax\', cfg.vertInertiaMax)" ng-disabled="locked || !cfg.vertInertia">',
            '<b>{{cfg.vertInertiaMax}}cm</b></div>',
          '<div class="sc-row sc-chk"><label><input type="checkbox" ng-model="cfg.engineVibe" ng-change="set(\'engineVibe\', cfg.engineVibe)" ng-disabled="locked"> Engine vibration<span class="sc-tipsrc" ng-if="tips.engineVibe">{{tips.engineVibe}}</span><span class="sc-info" ng-if="tips.engineVibe">&#9432;</span></label></div>',
          '<div class="sc-row" ng-class="{\'sc-dim\':!cfg.engineVibe}"><span>Vibration amount<span class="sc-tipsrc" ng-if="tips.vibeAmount">{{tips.vibeAmount}}</span><span class="sc-info" ng-if="tips.vibeAmount">&#9432;</span></span>',
            '<input type="range" min="0" max="0.5" step="0.01" ng-model="cfg.vibeAmount" ng-change="set(\'vibeAmount\', cfg.vibeAmount)" ng-disabled="locked || !cfg.engineVibe">',
            '<b>{{cfg.vibeAmount}}cm</b></div>',
          '<div class="sc-row" ng-class="{\'sc-dim\':!cfg.engineVibe}"><span>Rotation amount<span class="sc-tipsrc" ng-if="tips.vibeRotAmount">{{tips.vibeRotAmount}}</span><span class="sc-info" ng-if="tips.vibeRotAmount">&#9432;</span></span>',
            '<input type="range" min="0" max="1" step="0.01" ng-model="cfg.vibeRotAmount" ng-change="set(\'vibeRotAmount\', cfg.vibeRotAmount)" ng-disabled="locked || !cfg.engineVibe">',
            '<b>{{cfg.vibeRotAmount}}°</b></div>',
        '</div>',

        '<div class="sc-hint" ng-if="modified">Tweaks are unsaved — use Reset to discard, or Save changes / Save as new in the Presets dropdown.</div>',
        '<div class="sc-confirm" ng-if="modal">',
          '<div class="sc-confirm-box">',
            '<div class="sc-confirm-text">{{modal.text}}</div>',
            '<input ng-if="modal.input" class="sc-preset-name sc-modal-input" type="text" ng-model="modal.value" placeholder="Preset name" ng-keydown="$event.keyCode===13 && modalYes()">',
            '<div class="sc-confirm-btns">',
              '<button ng-click="modalNo()">Cancel</button>',
              '<button class="yes" ng-class="{danger:modal.danger}" ng-click="modalYes()">{{modal.yes}}</button>',
            '</div>',
          '</div>',
        '</div>',
        '<div class="sc-settings" ng-if="settingsOpen" ng-click="closeSettings()">',
          '<div class="sc-settings-box" ng-click="$event.stopPropagation()">',
            '<div class="sc-settings-hd"><span>Settings</span><span class="sc-settings-x" ng-click="closeSettings()" title="Close">&#215;</span></div>',
            '<label class="sc-set-chk"><input type="checkbox" ng-model="mirrorSeat" ng-change="setMirror(mirrorSeat)"> Mirror settings on right-hand-drive cars<span class="sc-tipsrc" ng-if="tips.mirror">{{tips.mirror}}</span><span class="sc-info" ng-if="tips.mirror">&#9432;</span></label>',
            '<label class="sc-set-chk"><input type="checkbox" ng-model="notaryEnabled" ng-change="setNotary(notaryEnabled)"> Per-vehicle configs<span class="sc-tipsrc" ng-if="tips.notary">{{tips.notary}}</span><span class="sc-info" ng-if="tips.notary">&#9432;</span></label>',
            '<div class="sc-set-note">Remembers a separate config per vehicle. Coming soon — the toggle is saved for when it lands.</div>',
            '<div class="sc-set-ver">SteerCam v{{version}} &middot; by LarsGudm</div>',
            '<button class="sc-set-close" ng-click="closeSettings()">Close</button>',
          '</div>',
        '</div>',
      '</div>'
    ].join(''),
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      // fallback list; replaced by the real (file-scanned) list once Lua answers
      scope.presetNames = ['Default', "Dev's Preset"];
      scope.protectedMap = { 'Default': true, "Dev's Preset": true };   // name -> safe tag
      scope.modal = null;         // shared confirm/prompt overlay {text, yes, action, input?, value?}
      scope.preset = 'Default';
      scope.modified = false;     // true when the selected preset has unsaved overrides
      scope.locked = false;       // every profile is editable now (kept for ng-disabled refs)
      scope.glanceSide = 'none';
      scope.modEnabled = true;   // global mod on/off (independent of preset lock)
      scope.mirrorSeat = true;   // global: mirror side-specific settings on RHD cars
      scope.notaryEnabled = false;   // per-vehicle configs (placeholder; not active yet)
      scope.settingsOpen = false;    // the Settings overlay
      scope.version = '1.0';         // shown in Settings; replaced by the Lua value on load
      // Hover hints (shown in the bottom hint bar). Add text to give a category/
      // control a hint, leave it '' for none. UI text only -- not per-preset, so it
      // lives here, not in the preset JSONs. Keyed by category id / setting name.
      scope.tips = {
        modEnable: '',
        mirror: 'Settings describe a left-hand-drive seat. In right-hand-drive cars; camera pan, glance angle, etc. auto-mirror so it feels the same.',
        notary: 'When on, each vehicle remembers its own SteerCam config automatically. Not active yet — the toggle is saved for when the feature ships.',
        cam: '',
        steer: 'Turns the view camera view based on steering input',
        glance: 'Snap the view to different angles. Bind keys in Options > Controls > Camera',
        speed: 'Optional immersive effects: FOV vertigo, corner head-roll, and vertical head inertia. Off by default.',
        camFwd: '',
        camUp: '',
        camYaw: '',
        camPitch: '',
        stableHorizon: '0 = horizon banks fully with the car; 100 = stays level (eases off on steep banks). Same as the game\'s Lock-roll-to-horizon.',
        camFov: '',
        nearClip: 'How close to the camera things start drawing. Lower hides nearby geometry (e.g. the roof poking in at high FOV); too low can cause flicker on distant surfaces. Recommended is 0.02 - 0.05 m (Game native is 0.1 m).',
        angle: 'How far the view turns at full steering lock.',
        reach: 'How much steering reaches the full angle. Lower = more reactive to small inputs.',
        stiffness: 'How quickly the camera moves. Higher = snappier.',
        reverseSteer: 'While reversing, mirror the turn the other way.',
        reverseAngle: '',
        reverseTime: 'How slowly camera eases between forward and reverse steering angle. Determined by movement vector and gear.',
        speedFade: 'Scale the camera pan by speed: none when stopped, full by Fade speed.',
        fadeSpeed: 'Speed at which the camera pan reaches full strength.',
        fadeFloor: 'How much of the camera pan is kept even at a standstill. 0 = none until moving.',
        glanceLeft: '',
        glanceRight: '',
        glanceTransition: 'How glance time is used. None = instant snap. Fixed time = same time for any angle. Constant speed = time scales with the angle, like turning your head at a steady rate (glance time = a full 180° turn).',
        glanceTime: '',
        glanceCurve: 'Easing curve for the glance motion.',
        glanceOffsetLeft: '',
        glanceOffsetRight: '',
        vertigo: 'Widen the FOV as you speed up, with a matching forward dolly (the vertigo warp).',
        vertigoFov: 'Max extra FOV added by the time you reach the speed range.',
        vertigoDolly: 'Distance kept "pinned" by the counter-dolly. 0 = FOV only, no camera move.',
        speedRoll: 'Lean the head into corners. Source is set below; max lean is Roll change.',
        rollSource: 'What drives the corner lean. Steering = from steering input, scaled by speed. Inertia = from real lateral g-force (full lean at ~1g), so it follows actual cornering load and slides.',
        rollAngle: 'Max lean angle (at full steering / speed range, or ~1g of cornering in Inertia mode).',
        speedRange: 'Speed at which the both the vertigo and speed roll effects will reach full strength.',
        vertInertia: 'Driver lifts off the seat when the car drops away (cresting, going light, airborne) and sinks under compression. A vertical offset on top of the camera Up offset.',
        vertInertiaMax: 'How far the head can travel at most (full at ~1g of vertical g-force).',
        engineVibe: 'A small rapid camera shake as the engine fires up (just after a brief ignition delay), plus a gentler quarter-strength shudder when you switch it off. (Road texture is mostly absorbed by the suspension, so it is not simulated.)',
        vibeAmount: 'How far the shake moves the camera at its peak. Small on purpose, so it reads as a buzz without being nauseating.',
        vibeRotAmount: 'How much the shake also rotates the view at its peak. Keep it tiny - a fraction of a degree feels best.'
      };
      // per-section twirl state; every section starts open (none collapsed)
      scope.collapsed = { cam: false, steer: false, glance: false, speed: false };
      scope.openDD = null;   // open custom dropdown ('preset'|'curve'|'transition'|'rollSource'|null)
      scope.curveOptions = [
        { k: 'Exponential', l: 'Exponential (native)' },
        { k: 'Linear', l: 'Linear' },
        { k: 'S-curve', l: 'S-curve' },
        { k: 'Ease1', l: 'Ease1' },
        { k: 'Ease2', l: 'Ease2' }
      ];
      scope.curveLabel = function (k) {
        for (var i = 0; i < scope.curveOptions.length; i++) {
          if (scope.curveOptions[i].k === k) { return scope.curveOptions[i].l; }
        }
        return k;
      };
      // how the glance tween is timed (see steercam.lua): instant / fixed duration /
      // distance-scaled so the turn rate is constant ("spin your head" feel).
      scope.transitionOptions = [
        { k: 'None', l: 'None (instant)' },
        { k: 'Fixed time', l: 'Fixed time' },
        { k: 'Constant speed', l: 'Constant speed' }
      ];
      scope.transitionLabel = function (k) {
        for (var i = 0; i < scope.transitionOptions.length; i++) {
          if (scope.transitionOptions[i].k === k) { return scope.transitionOptions[i].l; }
        }
        return k;
      };
      // what drives the corner head-roll (see steercam.lua): steering input vs the
      // real lateral g-force ("inertia"), which follows actual cornering load.
      scope.rollSourceOptions = [
        { k: 'Steering', l: 'Steering input' },
        { k: 'Inertia', l: 'Inertia (g-force)' }
      ];
      scope.rollSourceLabel = function (k) {
        for (var i = 0; i < scope.rollSourceOptions.length; i++) {
          if (scope.rollSourceOptions[i].k === k) { return scope.rollSourceOptions[i].l; }
        }
        return k;
      };
      scope.toggleDD = function (n) { scope.openDD = (scope.openDD === n) ? null : n; };

      // header text toggles the twirl only; the checkbox toggles enable
      scope.toggleCollapse = function (sec) { scope.collapsed[sec] = !scope.collapsed[sec]; };

      // section enable checkbox: toggle the feature only. Collapsing is left to
      // the header twisty so disabling a section doesn't hide its settings.
      scope.setEnable = function (sec, key, val) {
        scope.set(key, val);
      };

      // global mod on/off; works on any profile (not gated by the preset lock)
      scope.setMod = function (v) {
        bngApi.engineLua('if steerCam then steerCam.setEnabled(' + (v ? 'true' : 'false') + ') end');
      };

      // global driver-seat mirroring toggle (also independent of the preset lock)
      scope.setMirror = function (v) {
        bngApi.engineLua('if steerCam then steerCam.setMirror(' + (v ? 'true' : 'false') + ') end');
      };

      // per-vehicle notary toggle (placeholder: persisted, no behaviour yet)
      scope.setNotary = function (v) {
        bngApi.engineLua('if steerCam then steerCam.setNotary(' + (v ? 'true' : 'false') + ') end');
      };

      // ----- Settings overlay ----------------------------------------------------
      scope.openSettings = function () { scope.openDD = null; scope.settingsOpen = true; };
      scope.closeSettings = function () { scope.settingsOpen = false; };

      // "Save changes to this preset" is only valid on a non-protected preset that
      // actually has unsaved tweaks -- otherwise it's hidden.
      scope.canSaveChanges = function () {
        return scope.modified && !scope.protectedMap[scope.preset];
      };

      // open the presets folder in the OS file browser (find / share / hand-edit)
      scope.openPresetFolder = function () {
        scope.openDD = null;
        bngApi.engineLua('if steerCam then steerCam.openPresetFolder() end');
      };
      scope.cfg = {
        camEnable: true, camFwd: 0, camUp: 0, camYaw: 0, camPitch: 0, camFov: 65, stableHorizon: 0, nearClip: 0.05,
        steerEnable: true,
        angle: 18, reach: 35, stiffness: 15, reverseSteer: false, reverseAngle: 9, reverseTime: 500, speedFade: false, fadeSpeed: 30, fadeFloor: 0,
        glanceEnable: true,
        glanceLeft: 115, glanceRight: 115, glanceBack: 0, glanceTime: 120, glanceCurve: 'Exponential', glanceTransition: 'Fixed time',
        glanceOffsetLeft: 0.10, glanceOffsetRight: 0.10, glanceOffsetBack: 0, glanceBackRoll: 0,
        speedModEnable: true,
        vertigo: false, vertigoFov: 12, vertigoDolly: 0.30, speedRoll: false, rollAngle: 5, speedRange: 160,
        rollSource: 'Steering', vertInertia: false, vertInertiaMax: 8,
        engineVibe: false, vibeAmount: 0.2, vibeRotAmount: 0.15
      };

      function pushOne(key, val) {
        if (typeof val === 'boolean') {
          bngApi.engineLua("if steerCam then steerCam.set('" + key + "', " + (val ? 'true' : 'false') + ") end");
        } else if (typeof val === 'string') {
          bngApi.engineLua("if steerCam then steerCam.set('" + key + "', '" + val + "') end");
        } else {
          var n = parseFloat(val);
          if (isNaN(n)) { return; }
          bngApi.engineLua("if steerCam then steerCam.set('" + key + "', " + n + ") end");
        }
        // any edit writes the selected preset's override layer -> mark it modified live
        scope.modified = true;
      }

      // reflect the LIVE glance (hold keybind > toggle keybind > UI preview) so the
      // Preview buttons highlight whenever a glance is active -- from ANY source --
      // and clear the instant it ends. Polled, so keybind glances update the UI too.
      function syncGlance() {
        bngApi.engineLua('steerCam and steerCam.getGlanceState() or nil', function (st) {
          if (st && typeof st === 'object') {
            scope.$applyAsync(function () {
              var s = st.hold || st.toggle || st.preview || 0;
              scope.glanceSide = (s === 1) ? 'left' : (s === -1) ? 'right' : (s === 2) ? 'back' : 'none';
            });
          }
        });
      }

      // pull the file-scanned preset list (bundled + user-dropped .json files)
      function loadPresetNames() {
        // getPresetMeta returns [{name, protected}, ...]; derive the name list + a
        // name->protected map (so the dropdown can show a lock and block actions).
        bngApi.engineLua('steerCam and steerCam.getPresetMeta() or nil', function (meta) {
          if (!meta || typeof meta !== 'object') { return; }
          var arr = [], prot = {};
          for (var k in meta) {
            if (!meta.hasOwnProperty(k)) { continue; }
            var m = meta[k];
            if (m && typeof m === 'object' && m.name) {
              arr.push(m.name);
              if (m.protected) { prot[m.name] = true; }
            }
          }
          if (arr.length) {
            scope.$evalAsync(function () { scope.presetNames = arr; scope.protectedMap = prot; });
          }
        });
      }

      function load() {
        loadPresetNames();
        bngApi.engineLua('steerCam and steerCam.getCfg() or nil', function (cfg) {
          if (cfg && typeof cfg === 'object') {
            scope.$evalAsync(function () {
              for (var k in cfg) {
                if (scope.cfg.hasOwnProperty(k)) { scope.cfg[k] = cfg[k]; }
              }
              if (cfg.preset) { scope.preset = cfg.preset; }
              scope.modified = !!cfg.modified;
              if (typeof cfg.modEnabled === 'boolean') { scope.modEnabled = cfg.modEnabled; }
              if (typeof cfg.mirrorSeat === 'boolean') { scope.mirrorSeat = cfg.mirrorSeat; }
              if (typeof cfg.notaryEnabled === 'boolean') { scope.notaryEnabled = cfg.notaryEnabled; }
              if (cfg.version) { scope.version = cfg.version; }
              // collapse state is independent of enable state; every section starts
              // open so toggling a section off never hides its settings.
              scope.collapsed = { cam: false, steer: false, glance: false, speed: false };
            });
          }
        });
        syncGlance();
      }

      // pick a preset (escape any apostrophe, e.g. "Dev's Preset", for the Lua call)
      scope.choose = function (name) {
        var safe = name.replace(/'/g, "\\'");
        bngApi.engineLua("if steerCam then steerCam.setPreset('" + safe + "') end");
        scope.preset = name;
        load(); // refresh the shown values (+ modified flag) for the selected profile
      };

      // Reset: discard this preset's unsaved tweaks (no confirm, by design)
      scope.resetChanges = function () {
        bngApi.engineLua("steerCam and steerCam.resetOverrides() or nil", function () {
          scope.$evalAsync(function () { load(); });
        });
      };

      // Save changes to the current (non-protected) preset -- confirm, then bake in
      scope.saveChanges = function () {
        scope.openDD = null;
        var name = scope.preset;
        scope.modal = { text: 'Save changes to the preset "' + name + '"?', yes: 'Save', action: function () {
          bngApi.engineLua("steerCam and steerCam.saveChanges() or nil", function () {
            scope.$evalAsync(function () { load(); });
          });
        } };
      };

      // ----- preset save / delete (GE Lua writes/removes the JSON files) ---------
      // engineLua wraps a callback'd command as a FUNCTION ARGUMENT, so the command
      // MUST be an EXPRESSION ("steerCam and steerCam.x() or nil"), never an
      // "if ... end" statement -- a statement there is a Lua syntax error and the
      // whole call silently fails.
      function escq(s) { return String(s).replace(/\\/g, '\\\\').replace(/'/g, "\\'"); }

      // write the current effective settings to a (new or overwritten) preset file
      function doSavePreset(name) {
        bngApi.engineLua("steerCam and steerCam.savePreset('" + escq(name) + "') or nil", function () {
          scope.$evalAsync(function () { load(); });
        });
      }

      // a preset is deletable when it's not protected (Default/Dev's)
      scope.canDelete = function (name) {
        return !!name && !scope.protectedMap[name];
      };

      // dropdown "Save as new preset...": prompt for a name, then create -- or confirm
      // an overwrite if it exists. Protected/reserved names are blocked. Spaces and
      // accents are fine in the name (the filename gets slugified Lua-side).
      scope.saveAsNew = function () {
        scope.openDD = null;
        scope.modal = { input: true, value: '', text: 'Name this preset:', yes: 'Save', action: function (val) {
          var name = (val || '').replace(/^\s+|\s+$/g, '');
          if (!name) { return; }
          if (name === 'Custom' || scope.protectedMap[name]) {
            scope.modal = { text: '"' + name + '" is protected. Pick another name.', yes: 'OK', action: null };
            return;
          }
          if (scope.presetNames.indexOf(name) !== -1) {
            scope.modal = { text: 'Overwrite the existing preset "' + name + '"?', yes: 'Overwrite', action: function () { doSavePreset(name); } };
            return;
          }
          doSavePreset(name);
        } };
      };

      // dropdown per-row delete: confirm, then remove the file (Lua re-selects Default)
      scope.askDeletePreset = function (name) {
        if (!scope.canDelete(name)) { return; }
        scope.openDD = null;
        scope.modal = { text: 'Delete the preset "' + name + '"? This permanently removes its file.', yes: 'Delete', danger: true, action: function () {
          bngApi.engineLua("steerCam and steerCam.deletePreset('" + escq(name) + "') or nil", function () {
            scope.$evalAsync(function () { load(); });
          });
        } };
      };

      // shared modal: Yes runs the action (passing the input value, if any); the
      // action may open a follow-up modal (e.g. the overwrite confirm).
      scope.modalYes = function () {
        var m = scope.modal; scope.modal = null;
        if (m && m.action) { m.action(m.value); }
      };
      scope.modalNo = function () { scope.modal = null; };

      // edit a slider/checkbox (writes the selected preset's override layer)
      scope.set = function (key, val) {
        if (scope.locked) { return; }
        pushOne(key, val);
      };

      // preview buttons: latch the glance for a side so the angle can be tuned
      // live. Works on either profile (no lock), unlike the sliders.
      scope.toggleGlance = function (side) {
        scope.glanceSide = (scope.glanceSide === side) ? 'none' : side;
        var on = (scope.glanceSide === side);
        bngApi.engineLua("if steerCam then steerCam.glanceSet('" + side + "', " + (on ? 'true' : 'false') + ") end");
      };

      // pick a glance easing curve (button group; native <select> doesn't open in the UI)
      scope.setCurve = function (name) {
        if (scope.locked) { return; }
        scope.cfg.glanceCurve = name;
        pushOne('glanceCurve', name);
      };

      // pick how the glance transition is timed (None / Fixed time / Constant speed)
      scope.setTransition = function (name) {
        if (scope.locked) { return; }
        scope.cfg.glanceTransition = name;
        pushOne('glanceTransition', name);
      };

      // pick what drives the corner head-roll (Steering / Inertia)
      scope.setRollSource = function (name) {
        if (scope.locked) { return; }
        scope.cfg.rollSource = name;
        pushOne('rollSource', name);
      };

      // close an open custom dropdown when clicking/tapping anywhere outside it
      function ddOutside(e) {
        if (!scope.openDD) { return; }
        var n = e.target;
        while (n) {
          if (n.classList && n.classList.contains('sc-dd')) { return; } // inside a dropdown
          n = n.parentNode;
        }
        scope.$applyAsync(function () { scope.openDD = null; });
      }
      document.addEventListener('mousedown', ddOutside, true);
      scope.$on('$destroy', function () { document.removeEventListener('mousedown', ddOutside, true); });

      // Hover bubble: a white tooltip that STICKS TO THE CURSOR (below-right so the
      // pointer doesn't cover it) for whichever labelled control you're hovering, and
      // vanishes the moment you leave it. Reads the hidden .sc-tipsrc carrier text.
      // Lives on <body> so the panel's overflow can't clip it. (md-tooltip mis-
      // positioned in our app, so this is our own.)
      var bubble = document.createElement('div');
      bubble.className = 'sc-bubble';
      document.body.appendChild(bubble);
      var TIP_DELAY = 500;            // ms to hover before the bubble appears
      var tipTimer = null, tipHostEl = null, tipText = '';
      var mx = 0, my = 0;            // latest cursor position
      function clearTipTimer() { if (tipTimer) { clearTimeout(tipTimer); tipTimer = null; } }
      function hideBubble() { clearTipTimer(); tipHostEl = null; bubble.style.display = 'none'; }
      function placeBubble() {       // follow the cursor, clamped to stay on-screen
        var bw = bubble.offsetWidth, bh = bubble.offsetHeight;
        var x = mx + 16, y = my + 18;
        if (x + bw > window.innerWidth - 4) { x = mx - bw - 16; }
        if (y + bh > window.innerHeight - 4) { y = my - bh - 16; }
        if (x < 4) { x = 4; }
        if (y < 4) { y = 4; }
        bubble.style.left = x + 'px';
        bubble.style.top = y + 'px';
      }
      function tipHost(node) {
        while (node && node !== element[0]) {
          var kids = node.children;
          if (kids) {
            for (var i = 0; i < kids.length; i++) {
              if (kids[i].classList && kids[i].classList.contains('sc-tipsrc')) {
                return { host: node, text: (kids[i].textContent || '').trim() };
              }
            }
          }
          node = node.parentNode;
        }
        return null;
      }
      function onHover(e) {
        var h = tipHost(e.target);
        if (h && h.text) {
          if (h.host === tipHostEl) { return; }   // same control: already armed/showing
          tipHostEl = h.host;
          tipText = h.text;
          clearTipTimer();
          bubble.style.display = 'none';
          tipTimer = setTimeout(function () {      // show after a hover dwell, at the cursor
            bubble.textContent = tipText;
            bubble.style.display = 'block';
            placeBubble();
          }, TIP_DELAY);
        } else {
          hideBubble();
        }
      }
      function onMove(e) {
        mx = e.clientX; my = e.clientY;
        if (bubble.style.display === 'block') { placeBubble(); }
      }
      element[0].addEventListener('mouseover', onHover, true);
      element[0].addEventListener('mousemove', onMove, true);
      element[0].addEventListener('mouseleave', hideBubble);
      scope.$on('$destroy', function () {
        element[0].removeEventListener('mouseover', onHover, true);
        element[0].removeEventListener('mousemove', onMove, true);
        element[0].removeEventListener('mouseleave', hideBubble);
        clearTipTimer();
        if (bubble.parentNode) { bubble.parentNode.removeChild(bubble); }
      });

      // poll the glance preview state so the Preview buttons un-highlight when a
      // glance keybind cancels the preview (Lua clears it; the UI can't know otherwise)
      var glancePoll = setInterval(syncGlance, 200);
      scope.$on('$destroy', function () { clearInterval(glancePoll); });

      element.ready(function () {
        load();
        setTimeout(load, 600);
      });
    }
  };
}]);
