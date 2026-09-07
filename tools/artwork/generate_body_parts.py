"""Original path-based SVG artwork. Run from any directory; no raster dependencies."""
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parents[2]
MEDIA = ROOT / 'entry/src/main/resources/base/media'

DEFS = '''<defs>
  <linearGradient id="body" x1="0" y1="0" x2="1" y2="1">
    <stop stop-color="#E2EBED"/><stop offset=".46" stop-color="#AFBFC7"/><stop offset="1" stop-color="#708994"/>
  </linearGradient>
  <linearGradient id="muscle" x1="0" y1="0" x2=".8" y2="1">
    <stop stop-color="#F0F5F4"/><stop offset=".4" stop-color="#CDDADF"/><stop offset="1" stop-color="#91A7B2"/>
  </linearGradient>
  <linearGradient id="target" x1="0" y1="0" x2=".85" y2="1">
    <stop stop-color="#8EE4BC"/><stop offset=".35" stop-color="#39B38D"/><stop offset=".72" stop-color="#168269"/><stop offset="1" stop-color="#0B534D"/>
  </linearGradient>
  <linearGradient id="targetDeep" x1="0" y1="0" x2="1" y2=".8">
    <stop stop-color="#53CBA1"/><stop offset=".65" stop-color="#168269"/><stop offset="1" stop-color="#083D3D"/>
  </linearGradient>
  <linearGradient id="skin" x1="0" y1="0" x2="1" y2="1">
    <stop stop-color="#EDD0AD"/><stop offset=".5" stop-color="#C99670"/><stop offset="1" stop-color="#946345"/>
  </linearGradient>
  <linearGradient id="kit" x1="0" y1="0" x2="1" y2="1">
    <stop stop-color="#405764"/><stop offset="1" stop-color="#142C39"/>
  </linearGradient>
</defs>'''


def path(d, fill='url(#muscle)', stroke='#627D88', width=1.2, extra=''):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round" {extra}/>'


def line(d, color='#718C96', width=1.1, opacity=.65):
    return path(d, 'none', color, width, f'opacity="{opacity}"')


def paired(shape):
    return shape + f'<g transform="translate(320 0) scale(-1 1)">{shape}</g>'


def muscle(d, region, selected, deep=False):
    active = region in selected
    fill = 'url(#targetDeep)' if active and deep else 'url(#target)' if active else 'url(#muscle)'
    return path(d, fill, '#246E62' if active else '#7C949E')


def fibers(paths, active=False):
    return ''.join(line(d, '#C6F4DB' if active else '#F0F6F6', 1.1, .55) for d in paths)


def front(selected):
    # Neck, broad shoulder girdle, arms and tapering torso form a continuous silhouette.
    out = paired(path('M160 18 L142 16 L141 36 C132 44 112 46 94 53 C75 49 56 60 51 80 '
                      'C43 99 47 119 42 137 C37 156 34 172 27 192 L20 216 '
                      'C17 225 22 234 30 234 L40 226 L48 204 C58 188 61 169 68 154 '
                      'C76 136 80 119 83 104 L92 112 C94 144 109 163 115 185 '
                      'L115 221 L107 244 L160 260 Z', 'url(#body)'))
    out += paired(muscle('M143 27 C139 40 116 42 99 54 L124 59 L155 49 Z', 'trap', selected))
    # Three-dimensional deltoid cap and distinct upper-arm muscle bellies.
    out += paired(muscle('M95 54 C77 50 59 58 54 73 C50 84 52 95 58 102 '
                         'C66 92 77 89 88 86 L101 64 Z', 'shoulder', selected))
    out += paired(muscle('M56 103 C57 91 64 84 75 80 C71 105 69 118 63 132 '
                         'L52 142 C50 128 52 115 56 103 Z', 'arm', selected, True))
    out += paired(muscle('M78 91 C88 98 80 129 69 146 C64 152 56 151 54 144 '
                         'C58 128 66 104 78 91 Z', 'arm', selected))
    out += paired(muscle('M54 153 C62 148 67 151 64 160 C58 179 48 198 40 213 '
                         'L32 217 C36 196 40 172 54 153 Z', 'arm', selected, True))
    out += paired(line('M49 163 C45 181 37 199 32 213 M26 218 L25 227 M31 220 L29 230 M36 218 L34 227'))
    # Pectorals split cleanly at the sternum, with separate clavicular fibers.
    out += paired(muscle('M99 60 C115 57 140 54 156 62 L157 106 '
                         'C145 120 120 118 106 107 C94 97 89 82 91 73 Z', 'chest', selected))
    out += paired(line('M100 68 C120 63 140 66 151 70', '#F5FBF8', 1.6, .65))
    out += paired(fibers(['M101 77 Q130 72 151 78', 'M103 87 Q130 85 151 88', 'M110 100 Q131 99 151 98'], 'chest' in selected))
    # Serratus slips, obliques, rectus abdominis and iliac crest.
    out += paired(muscle('M98 108 L117 118 L119 128 L105 122 Z', 'core', selected))
    out += paired(muscle('M104 125 L122 133 L123 144 L111 137 Z', 'core', selected, True))
    out += paired(muscle('M112 143 L126 152 L126 164 L117 160 Z', 'core', selected))
    for d in [
        'M136 121 Q145 117 155 119 L156 139 Q144 144 132 138 Z',
        'M133 144 Q145 148 156 144 L156 164 Q143 169 131 162 Z',
        'M132 169 Q144 174 156 170 L156 190 Q143 195 134 187 Z',
        'M136 194 Q146 199 156 195 L156 218 L145 225 L136 210 Z',
    ]:
        out += paired(muscle(d, 'abs', selected))
    out += paired(muscle('M121 164 L129 174 L130 205 L141 229 '
                         'C128 224 119 213 119 199 Z', 'core', selected, True))
    out += paired(line('M119 217 Q130 230 151 240 M121 182 L125 197', '#607E88', 1.5))
    out += line('M160 59 L160 111 M160 121 L160 188', '#526E7A', 1.1, .65)
    out += '<ellipse cx="160" cy="193" rx="2" ry="3" fill="#536E79"/>'
    out += paired(fibers(['M65 72 Q75 61 86 60', 'M65 107 Q72 97 75 96', 'M56 159 Q48 178 43 195'], 'arm' in selected))
    return out


def back():
    out = paired(path('M160 17 L143 18 L141 36 L102 51 C77 46 58 58 54 80 '
                      'L43 140 L27 195 L24 222 L35 233 L45 215 L64 171 L82 111 '
                      'L94 111 Q99 152 115 181 L119 218 L109 244 L160 255 Z', 'url(#body)'))
    out += paired(muscle('M143 30 Q127 46 100 54 L126 88 L157 119 L157 43 Z', 'back', ['back']))
    out += paired(muscle('M97 59 Q78 53 63 66 Q54 79 59 100 L89 86 Z', '', []))
    out += paired(muscle('M97 71 Q119 84 134 100 L116 116 Q99 108 92 91 Z', 'back', ['back']))
    out += paired(muscle('M94 101 Q109 119 134 110 L155 126 L153 181 '
                         'Q130 175 114 153 Q100 135 94 101 Z', 'back', ['back'], True))
    out += paired(muscle('M151 132 L144 169 L133 207 L156 224 Z', 'back', ['back']))
    out += paired(muscle('M69 95 Q86 104 69 144 Q64 155 55 151 L57 128 Z', '', []))
    out += paired(muscle('M54 158 Q65 151 61 166 L43 212 L33 219 Q36 185 54 158 Z', '', []))
    out += paired(line('M126 184 Q120 206 130 220 L153 236 M34 222 L32 229', '#627F89', 1.4))
    out += line('M160 34 L160 226', '#D9EFE7', 2, .9)
    out += paired(fibers(['M140 45 Q128 58 118 63', 'M140 64 Q130 73 127 81',
                          'M101 112 Q115 132 145 143', 'M108 131 Q122 149 145 154',
                          'M117 149 Q130 163 145 166', 'M148 178 L143 200'], True))
    return out


def glutes():
    out = paired(path('M160 26 L115 23 L116 48 Q107 69 98 90 C88 109 91 143 96 163 '
                      'L104 239 L143 241 L151 169 L160 156 Z', 'url(#body)'))
    out += paired(muscle('M118 31 L157 35 L157 73 L132 87 L112 71 Z', '', []))
    out += paired(muscle('M112 73 C97 81 94 96 97 112 L119 108 L139 88 Z', 'glute', ['glute']))
    out += paired(muscle('M138 84 C117 85 96 100 96 123 C93 145 110 158 129 155 '
                         'C147 156 156 145 157 131 L157 97 Z', 'glute', ['glute']))
    out += paired(muscle('M105 157 Q120 167 135 160 L127 237 L109 236 Z', '', []))
    out += paired(muscle('M140 159 L152 153 L143 240 L132 240 Z', '', []))
    out += line('M160 34 L160 69 M150 77 L160 85 L170 77 M160 97 L160 136', '#65818C', 1.6)
    out += paired(fibers(['M109 100 Q128 90 147 99', 'M104 113 Q124 100 149 108',
                          'M104 126 Q126 110 150 119', 'M110 139 Q133 122 150 131'], True))
    out += paired(line('M115 176 L116 220', '#F4F9F7', 1.3, .8))
    return out


def legs():
    out = paired(path('M160 21 L116 18 C101 51 104 77 112 110 L114 135 '
                      'C104 158 111 179 121 209 L119 224 L106 237 Q103 244 115 245 '
                      'L141 244 L143 226 L147 188 Q157 160 150 137 L151 102 L160 69 Z', 'url(#body)'))
    # Briefs keep the crop neutral while exposing the quadriceps and adductors.
    out += paired(path('M117 18 L160 22 L160 59 L147 82 L130 72 L109 63 Z', 'url(#kit)', '#415C67'))
    out += paired(muscle('M113 70 Q119 66 125 78 C121 99 122 116 127 133 '
                         'Q117 137 114 125 C106 105 106 81 113 70 Z', 'leg', ['leg'], True))
    out += paired(muscle('M130 76 Q144 77 145 96 L139 128 Q133 141 128 129 '
                         'C123 112 123 91 130 76 Z', 'leg', ['leg']))
    out += paired(muscle('M146 83 L153 72 L148 124 Q149 140 140 142 L136 136 Z', 'leg', ['leg'], True))
    out += paired(path('M125 138 Q132 134 140 141 L139 151 L127 154 L121 148 Z', 'url(#muscle)'))
    out += paired(muscle('M119 157 Q129 155 129 166 L130 200 L124 212 '
                         'C116 192 111 172 119 157 Z', 'leg', ['leg']))
    out += paired(muscle('M135 157 Q147 148 148 163 Q149 185 135 205 L132 211 Z', 'leg', ['leg'], True))
    out += paired(line('M130 210 L127 226 M136 209 L135 228 M119 234 L132 235', '#65818C', 1.5))
    out += paired(fibers(['M133 87 Q129 107 133 123', 'M114 81 Q112 100 118 120', 'M123 164 L124 189'], True))
    return out


def arm():
    # A flexed arm, drawn as muscle volumes instead of a stroke skeleton.
    out = path('M64 217 C65 190 73 166 83 153 C87 142 99 133 112 132 '
               'L151 124 L176 116 L184 90 L178 62 L176 44 C176 36 183 33 190 34 '
               'L205 38 C214 38 219 46 216 53 L210 62 L211 86 '
               'C218 111 214 134 207 149 C198 164 181 174 161 181 '
               'L139 188 L132 222 Z', 'url(#body)')
    out += muscle('M84 154 C91 137 109 129 123 137 L141 155 C132 174 109 187 85 185 Z', 'arm', ['arm'])
    out += muscle('M115 142 C136 124 163 122 178 131 C190 138 179 154 165 160 '
                  'L140 168 C129 168 121 158 115 142 Z', 'arm', ['arm'])
    out += muscle('M92 187 Q115 181 133 165 L156 175 Q148 190 131 198 L125 219 L70 219 Z', 'arm', ['arm'], True)
    out += muscle('M181 120 L189 87 L187 65 L202 63 C207 87 211 112 201 135 '
                  'Q193 145 185 141 Z', 'arm', ['arm'], True)
    out += muscle('M173 131 Q181 116 181 104 L189 72 L195 71 L196 101 '
                  'Q196 124 182 139 Z', 'arm', ['arm'])
    out += path('M177 44 Q180 37 187 40 L197 44 L206 42 L211 47 L206 56 '
                'L195 59 L185 54 Z', 'url(#muscle)')
    out += line('M185 43 L193 48 M191 41 L201 46 M193 55 L201 52 M180 49 L186 55')
    out += fibers(['M95 153 Q107 144 117 148', 'M129 143 Q150 132 165 138',
                   'M132 151 Q150 140 170 144', 'M187 94 L188 118',
                   'M86 197 Q113 192 126 179'], True)
    return out


def runner():
    out = '<ellipse cx="162" cy="238" rx="95" ry="5" fill="#345D60" opacity=".10"/>'
    # Far arm, far leg and shoe establish depth behind the running figure.
    out += path('M181 73 Q193 72 201 90 L216 104 L236 90 L243 81 '
                'Q250 77 253 84 L250 94 L221 120 Q214 123 207 117 L184 99 Z', 'url(#skin)', '#9A7256')
    out += path('M151 133 L172 145 Q158 170 135 186 Q121 197 107 190 '
                'L74 172 L69 160 L82 159 L116 176 L139 147 Z', 'url(#skin)', '#9A7256')
    out += path('M78 157 L83 171 L70 177 Q64 175 59 166 L49 153 Q47 147 53 144 '
                'L60 146 L66 156 Z', 'url(#kit)', '#243E4B')
    out += path('M50 151 L62 166 L70 171 L79 168 L82 173 L70 180 Q63 178 57 169 L46 154 Z', '#EDF2EB', '#738F96', .8)
    out += line('M62 153 L70 159 M59 157 L67 163', '#92DCC4', 1.5, 1)
    # Forward thigh and calf have distinct silhouettes and shaded muscle planes.
    out += path('M165 133 Q188 139 203 154 L218 170 Q226 180 219 193 '
                'L195 227 L181 225 Q187 203 201 183 L178 173 L156 157 Z', 'url(#skin)', '#9A7256')
    out += path('M188 151 Q207 165 212 174 Q217 182 210 187 '
                'L193 171 L176 163 Z', '#B8815E', 'none')
    out += path('M207 191 Q214 190 210 200 L194 221 L188 218 Z', '#E5BC94', 'none')
    out += path('M181 219 L196 224 L195 234 L215 238 Q221 242 216 247 '
                'L178 246 Q174 240 178 230 Z', 'url(#kit)', '#243E4B')
    out += path('M177 241 Q193 244 218 242 L218 248 L178 248 Z', '#EDF2EB', '#738F96', .8)
    out += line('M190 230 L198 232 M187 234 L202 237', '#92DCC4', 1.5, 1)
    # Shorts and fitted singlet articulate a powerful, forward-leaning torso.
    out += path('M145 118 L180 127 L187 147 L171 160 L158 146 L146 165 '
                'L128 153 Z', 'url(#kit)', '#243E4B')
    out += line('M158 129 L153 147 M133 151 L143 157 M177 147 L173 153', '#839FA6', 1.4, .7)
    out += path('M180 56 Q191 62 192 77 L185 104 L181 131 '
                'Q160 139 143 123 L151 95 Q151 71 163 62 Z', 'url(#target)', '#226B5E')
    out += path('M179 67 Q185 89 172 108 L166 132 L181 131 L185 104 L192 77 Z', '#0D6657', 'none')
    out += line('M158 107 Q169 112 177 108 M151 119 L160 122', '#A2E8C5', 1.3)
    out += path('M173 58 L178 46 L192 45 L191 64 L183 72 Z', 'url(#skin)', '#9A7256')
    # Profile: ear, jaw, nose, cropped hair and neck, rather than a circular head.
    out += path('M177 28 Q183 15 197 22 Q209 26 207 38 L212 46 L206 49 '
                'L204 58 Q199 64 187 56 L178 46 Z', 'url(#skin)', '#9A7256')
    out += path('M177 42 Q171 32 178 23 Q184 15 198 20 Q207 20 209 29 '
                'L203 34 L188 30 L184 40 Z', '#253B43', '#253B43')
    out += path('M184 39 Q178 36 178 43 Q179 48 184 47', '#DAB08A', '#9A7256', .8)
    out += line('M202 39 L205 40 M201 53 L204 53', '#79553F', 1.1, 1)
    # Near arm: rounded deltoid, biceps, elbow and clenched hand.
    out += path('M165 69 C154 63 146 73 139 86 L126 99 L108 87 L102 73 '
                'Q98 67 92 72 L88 80 L93 91 L117 113 Q127 120 137 111 '
                'L158 96 Q175 83 165 69 Z', 'url(#skin)', '#9A7256')
    out += path('M154 70 Q164 66 164 76 Q162 86 151 93 L139 102 L132 102 '
                'Q141 93 145 83 Z', '#E6BE98', 'none')
    out += line('M143 91 Q151 88 155 80 M116 105 L125 109 M93 77 L99 78 M92 82 L100 84', '#9A7256', 1, .8)
    out += line('M53 98 L89 98 M43 111 L79 111 M48 124 L68 124', '#7CB9A9', 2.5, .6)
    return out


ART = {
    'chest': ('胸部肌群', front(['chest']), '35 30 250 190'),
    'shoulder': ('肩部三角肌', front(['shoulder']), '27 25 266 172'),
    'back': ('背部肌群', back(), '35 26 250 205'),
    'arm': ('手臂肌群', arm(), '40 20 220 225'),
    'glute': ('臀部肌群', glutes(), '58 12 204 224'),
    'leg': ('腿部肌群', legs(), '68 7 184 247'),
    'abs': ('腹部肌群', front(['abs']), '87 102 146 144'),
    'core': ('核心肌群', front(['abs', 'core']), '76 96 168 154'),
    'cardio': ('有氧跑步', runner(), '18 8 270 250'),
}

for key, (title, body, crop) in ART.items():
    # Nested SVG provides a real crop without raster images, masks, fonts or filters.
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="320" height="240" viewBox="0 0 320 240">
<title>{escape(title)}</title>
<desc>原创运动肌群示意图，绿色强调训练区域；非医学解剖图。</desc>
{DEFS}
<ellipse cx="160" cy="124" rx="115" ry="105" fill="#E9F3EF"/>
<path d="M49 83 A116 106 0 0 1 226 34 M260 166 A116 106 0 0 1 102 221" fill="none" stroke="#C5DDD3" stroke-width="1.3"/>
<circle cx="52" cy="80" r="3" fill="#52AD8D"/>
<circle cx="260" cy="168" r="2" fill="#93C7B2"/>
<svg x="18" y="9" width="284" height="222" viewBox="{crop}" preserveAspectRatio="xMidYMid meet" overflow="hidden">
{body}
</svg>
</svg>
'''
    (MEDIA / f'part_{key}.svg').write_text(svg, encoding='utf-8')

print(f'Wrote {len(ART)} original SVG illustrations to {MEDIA}')
