import React, { useState, useRef, useEffect } from 'react';
import Navbar from '../components/layouts/Navbar';
import Footer from '../components/layouts/Footer';
import logo from '../assets/images/logo-booth-second.png';
import frameStrip1 from '../assets/strips/strip1.png';
import frameStrip2 from '../assets/strips/strip2.png';
import frameStrip3 from '../assets/strips/strip3.png';

// Data Template HD (1200 x 3600)
const templates = [
  {
    id: 1,
    name: 'Classic White Strip',
    image: frameStrip1,
    width: 1200,
    height: 3600,
    slots: [
      { x: 100, y: 200, w: 1000, h: 800 },
      { x: 100, y: 1200, w: 1000, h: 800 },
      { x: 100, y: 2200, w: 1000, h: 800 },
    ]
  },
  {
    id: 2,
    name: 'Orange Fresh Strip',
    image: frameStrip2,
    width: 1200,
    height: 3600,
    slots: [
      { x: 100, y: 200, w: 1000, h: 800 },
      { x: 100, y: 1200, w: 1000, h: 800 },
      { x: 100, y: 2200, w: 1000, h: 800 },
    ]
  },
  {
    id: 3,
    name: 'Blue Elegant Strip',
    image: frameStrip3,
    width: 1200,
    height: 3600,
    slots: [
      { x: 100, y: 200, w: 1000, h: 800 },
      { x: 100, y: 1200, w: 1000, h: 800 },
      { x: 100, y: 2200, w: 1000, h: 800 },
    ]
  }
];

const Photobooth = () => {
  const [step, setStep] = useState(1);
  const [selectedTemplate, setSelectedTemplate] = useState(null);
  const [photos, setPhotos] = useState([]);
  const [countdown, setCountdown] = useState(null);

  const videoRef = useRef(null);
  const canvasRef = useRef(null);
  const streamRef = useRef(null);

  useEffect(() => {
    if (step === 2) startCamera();
    else stopCamera();
    return () => stopCamera();
  }, [step]);

  const startCamera = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: true });
      if (videoRef.current) videoRef.current.srcObject = stream;
      streamRef.current = stream;
    } catch (err) {
      alert("Kamera tidak aktif.");
    }
  };

  const stopCamera = () => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop());
      streamRef.current = null;
    }
  };

  const handleSelectTemplate = (template) => {
    setSelectedTemplate(template);
    setPhotos([]);
    setStep(2);
  };

  const takePhotos = async () => {
    if (!videoRef.current || !selectedTemplate) return;
    const capturedPhotos = [];
    const totalPhotos = selectedTemplate.slots.length;

    for (let i = 0; i < totalPhotos; i++) {
      for (let c = 3; c > 0; c--) {
        setCountdown(c);
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
      setCountdown(null);

      const canvas = document.createElement('canvas');
      canvas.width = videoRef.current.videoWidth;
      canvas.height = videoRef.current.videoHeight;
      const ctx = canvas.getContext('2d');
      ctx.translate(canvas.width, 0);
      ctx.scale(-1, 1);
      ctx.drawImage(videoRef.current, 0, 0, canvas.width, canvas.height);

      const photoUrl = canvas.toDataURL('image/png');
      capturedPhotos.push(photoUrl);
      setPhotos([...capturedPhotos]);

      if (i < totalPhotos - 1) await new Promise(resolve => setTimeout(resolve, 1000));
    }

    setStep(3);
    setTimeout(() => generateResult(capturedPhotos), 100);
  };

  const generateResult = (capturedPhotos) => {
    if (!canvasRef.current || !selectedTemplate) return;
    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');
    canvas.width = selectedTemplate.width;
    canvas.height = selectedTemplate.height;

    ctx.fillStyle = '#ffffff';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    let loadedPhotos = 0;
    const drawFrame = () => {
      const bgImg = new Image();
      bgImg.crossOrigin = "anonymous";
      bgImg.src = selectedTemplate.image;
      bgImg.onload = () => {
        ctx.drawImage(bgImg, 0, 0, canvas.width, canvas.height);
      };
    };

    capturedPhotos.forEach((photoSrc, index) => {
      const slot = selectedTemplate.slots[index];
      const img = new Image();
      img.src = photoSrc;
      img.onload = () => {
        const scale = Math.max(slot.w / img.width, slot.h / img.height);
        const w = slot.w / scale;
        const h = slot.h / scale;
        const x = (img.width / 2) - (w / 2);
        const y = (img.height / 2) - (h / 2);
        ctx.drawImage(img, x, y, w, h, slot.x, slot.y, slot.w, slot.h);
        loadedPhotos++;
        if (loadedPhotos === capturedPhotos.length) drawFrame();
      };
    });
  };

  const downloadPhoto = () => {
    const link = document.createElement('a');
    link.download = 'memontra-photobooth.png';
    link.href = canvasRef.current.toDataURL('image/png');
    link.click();
  };

  return (
    <>
      <Navbar />
      <div className="pt-16 min-h-screen relative overflow-hidden bg-[#F8FAFC] flex flex-col items-center font-poppins text-dark">

        {/* BACKGROUND DEKORASI ELEGANT (Lebih Halus) */}
        <div className="absolute top-0 left-0 w-full h-[50vh] bg-gradient-to-b from-primary/10 to-transparent pointer-events-none"></div>
        <div className="absolute top-[-10%] right-[-5%] w-[40vw] h-[40vw] rounded-full bg-secondary/10 blur-[100px] pointer-events-none"></div>
        <div className="absolute bottom-[-10%] left-[-5%] w-[40vw] h-[40vw] rounded-full bg-primary/10 blur-[100px] pointer-events-none"></div>

        {/* Main Content Container */}
        <div className="relative z-10 w-full flex flex-col items-center py-10 px-4">

          {/* Header Title */}
          <img src={logo} alt="Memontra Photobooth" className="w-72 h-auto mb-1" />

          {/* STEP 1: PILIH TEMPLATE EKSKLUSIF */}
          {step === 1 && (
            <div className="w-full max-w-5xl animate-fade-in flex flex-col items-center mt-2">

              <p className="text-gray-500 mb-8 text-center max-w-lg">
                Pilih desain frame favoritmu sebelum memulai sesi foto.
              </p>

              {/* PANGGUNG GLASSMORPHISM */}
              <div className="w-full bg-white/40 backdrop-blur-xl border border-white/60 shadow-2xl rounded-3xl p-8 md:p-12 relative overflow-hidden">

                {/* Garis Kilau (Glow) di atas panggung */}
                <div className="absolute top-0 left-1/2 -translate-x-1/2 w-3/4 h-[2px] bg-gradient-to-r from-transparent via-primary/40 to-transparent"></div>

                <div className="flex flex-wrap justify-center gap-8 md:gap-12">
                  {templates.map(tpl => (
                    <div
                      key={tpl.id}
                      className="group cursor-pointer flex flex-col items-center"
                      onClick={() => handleSelectTemplate(tpl)}
                    >
                      {/* RAHASIA UKURAN PAS: 
                      Kita kunci tinggi (h-[45vh]) dan biarkan lebarnya menyesuaikan (aspect-[1/3]).
                      Jadi nggak akan pernah jebol ke bawah layar!
                    */}
                      <div className="relative h-[45vh] min-h-[280px] max-h-[400px] aspect-[1/3] bg-white border-4 border-transparent group-hover:border-secondary rounded-2xl shadow-lg overflow-hidden transition-all duration-500 transform group-hover:-translate-y-3 group-hover:shadow-secondary/30">

                        <img src={tpl.image} alt={tpl.name} className="w-full h-full object-cover" />

                        {/* Efek Hover Keren pas cursor ditaruh di frame */}
                        <div className="absolute inset-0 bg-primary/0 group-hover:bg-primary/20 backdrop-blur-[1px] transition-all duration-300 flex items-center justify-center">
                          <div className="bg-secondary text-white text-center px-5 py-2 rounded-full font-bold opacity-0 group-hover:opacity-100 transform translate-y-4 group-hover:translate-y-0 transition-all duration-300 shadow-xl">
                            Pilih Frame
                          </div>
                        </div>
                      </div>

                      {/* Judul Frame */}
                      <div className="mt-5 text-center">
                        <p className="font-bold text-dark group-hover:text-primary transition-colors text-lg">{tpl.name}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* STEP 2: AMBIL FOTO */}
          {step === 2 && (
            <div className="w-full max-w-2xl flex flex-col items-center animate-fade-in mt-4">
              <div className="bg-white/60 backdrop-blur-md px-6 py-2 rounded-full border border-white/80 mb-6 shadow-sm">
                <h2 className="text-xl font-bold text-primary text-center">Pose Terbaikmu dalam 3.. 2.. 1..</h2>
              </div>

              <div className="relative w-full aspect-video bg-black rounded-3xl overflow-hidden mb-8 shadow-2xl border-[6px] border-white ring-4 ring-primary/20">
                <video ref={videoRef} autoPlay playsInline muted className="w-full h-full object-cover transform -scale-x-100" />
                {countdown !== null && (
                  <div className="absolute inset-0 flex items-center justify-center bg-black/30 backdrop-blur-sm">
                    <span className="text-white text-[10rem] font-black drop-shadow-2xl">{countdown}</span>
                  </div>
                )}
              </div>

              <div className="flex gap-4">
                <button onClick={() => setStep(1)} className="px-8 py-3 bg-white border-2 border-primary text-primary rounded-full font-bold hover:bg-gray-50 transition shadow-sm">Kembali</button>
                <button onClick={takePhotos} disabled={countdown !== null} className="px-10 py-3 bg-primary text-white rounded-full font-bold hover:bg-opacity-90 shadow-lg disabled:opacity-50 transition hover:-translate-y-1">Mulai Foto!</button>
              </div>
            </div>
          )}

          {/* STEP 3: HASIL FOTO */}
          {step === 3 && (
            <div className="w-full max-w-3xl flex flex-col items-center animate-fade-in mt-4">
              <h2 className="text-3xl font-black mb-8 text-primary">Yeay! Ini Hasilnya.</h2>

              <div className="flex justify-center mb-10 w-full relative">
                {/* Efek Glow di Belakang Hasil Foto */}
                <div className="absolute inset-0 bg-secondary/20 blur-3xl rounded-full transform scale-75"></div>

                <canvas
                  ref={canvasRef}
                  className="relative z-10 max-w-full max-h-[70vh] h-auto border-4 border-white shadow-2xl rounded-md"
                />
              </div>

              <div className="flex gap-4">
                <button
                  onClick={() => { setStep(1); setPhotos([]); }}
                  className="px-8 py-3 bg-white border-2 border-primary text-primary rounded-full font-bold hover:bg-gray-50 transition"
                >
                  Ulangi
                </button>
                <button
                  onClick={downloadPhoto}
                  className="px-8 py-3 bg-secondary text-white rounded-full font-bold hover:shadow-xl hover:-translate-y-1 transition-all duration-300"
                >
                  Unduh Foto
                </button>
              </div>
            </div>
          )}

        </div>
      </div>
      <Footer />
    </>
  );
};

export default Photobooth;