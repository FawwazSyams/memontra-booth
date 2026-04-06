import React, { useEffect } from 'react';
import AOS from 'aos';
import 'aos/dist/aos.css';

const Features = () => {
    useEffect(() => {
        AOS.init({ duration: 800, once: true });
    }, []);

    const featureData = [
        {
            title: "Kualitas Kamera DSLR",
            desc: "Bukan sekadar webcam. Kami menggunakan kamera DSLR profesional untuk hasil foto yang super tajam dan jernih.",
            icon: "📸",
        },
        {
            title: "Cetak Cepat & Instan",
            desc: "Hitungan detik, momen langsung tercetak. Menggunakan mesin printer berkualitas agar warna tidak mudah pudar.",
            icon: "🖨️",
        },
        {
            title: "Desain Frame Kustom",
            desc: "Sesuaikan desain bingkai foto dengan tema acaramu. Gratis revisi desain hingga sesuai dengan keinginan.",
            icon: "🎨",
        },
        {
            title: "Akses Soft File QR Code",
            desc: "Langsung download foto digitalmu di tempat dengan memindai QR Code. Mudah dibagikan ke sosial media.",
            icon: "📱",
        },
        {
            title: "Properti Seru & Unik",
            desc: "Dilengkapi berbagai macam fun props (kacamata, topi, tulisan lucu) untuk membuat gayamu makin maksimal.",
            icon: "🎉",
        },
        {
            title: "Asisten Standby",
            desc: "Tim kami akan selalu stand-by di lokasi untuk memastikan alat berjalan lancar dan membantu tamu berpose.",
            icon: "👨‍💻",
        }
    ];

    return (
        <section id="fitur" className="py-20 bg-universal/50">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

                {/* Header Section */}
                <div className="text-center max-w-3xl mx-auto mb-16" data-aos="fade-up">
                    <h2 className="text-secondary font-semibold tracking-wider uppercase text-sm mb-2">Keunggulan Kami</h2>
                    <h3 className="text-3xl md:text-4xl font-bold text-primary mb-4">
                        Mengapa Memilih Memontra Booth?
                    </h3>
                    <p className="text-dark/70 text-lg">
                        Kami memastikan setiap senyuman terekam sempurna dengan peralatan terbaik dan pelayanan maksimal.
                    </p>
                </div>

                {/* Grid Cards */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
                    {featureData.map((feature, index) => (
                        <div
                            key={index}
                            data-aos="fade-up"
                            data-aos-delay={index * 100} // Efek muncul berurutan
                            className="bg-universal p-8 rounded-2xl shadow-[0_4px_20px_rgba(0,0,0,0.05)] border border-primary/10 hover:border-primary/30 hover:shadow-[0_8px_30px_rgba(28,123,127,0.15)] transition-all duration-300 group"
                        >
                            <div className="w-14 h-14 bg-primary/10 rounded-xl flex items-center justify-center text-3xl mb-6 group-hover:bg-primary group-hover:scale-110 transition-all duration-300">
                                <span className="group-hover:grayscale-0">{feature.icon}</span>
                            </div>
                            <h4 className="text-xl font-bold text-dark mb-3 group-hover:text-primary transition-colors">
                                {feature.title}
                            </h4>
                            <p className="text-dark/70 leading-relaxed text-sm">
                                {feature.desc}
                            </p>
                        </div>
                    ))}
                </div>

            </div>
        </section>
    );
};

export default Features;