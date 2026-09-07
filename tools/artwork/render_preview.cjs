const sharp = require('sharp');
const fs = require('fs');
const root = require('path').resolve(__dirname, '../..');
const parts=[['chest','胸'],['shoulder','肩'],['back','背'],['arm','手臂'],['glute','臀部'],['leg','腿'],['abs','腹部'],['core','核心'],['cardio','有氧']];
(async()=>{
for(const compact of [false,true]){
  const cw=compact?168:320, ch=compact?154:280, cols=compact?2:3, gap=16, margin=24, head=64;
  const w=cols*cw+(cols-1)*gap+margin*2,h=Math.ceil(9/cols)*(ch+gap)+head+margin;
  const layers=[];
  const bg=`<svg width="${w}" height="${h}"><rect width="100%" height="100%" fill="#EEF3F0"/><text x="24" y="38" font-family="Microsoft YaHei" font-size="23" font-weight="600" fill="#21463A">训练部位 · 肌群插画</text></svg>`;
  for(let i=0;i<parts.length;i++){
    const [key,name]=parts[i],x=margin+(i%cols)*(cw+gap),y=head+Math.floor(i/cols)*(ch+gap);
    const card=Buffer.from(`<svg width="${cw}" height="${ch}"><rect x=".5" y=".5" width="${cw-1}" height="${ch-1}" rx="20" fill="white" stroke="#DDE8E1"/><text x="${cw/2}" y="${ch-15}" text-anchor="middle" font-family="Microsoft YaHei" font-size="18" font-weight="600" fill="#21463A">${name}</text></svg>`);
    layers.push({input:card,left:x,top:y});
    const img=await sharp(`${root}/entry/src/main/resources/base/media/part_${key}.svg`).resize(cw-16,compact?100:228,{fit:'contain',background:'#ffffff00'}).png().toBuffer();
    layers.push({input:img,left:x+8,top:y+8});
  }
  await sharp(Buffer.from(bg)).composite(layers).png().toFile(`${root}/tools/artwork/${compact?'preview-compact':'preview'}.png`);
}
})();
