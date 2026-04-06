// src/sections/Pricing.jsx
import React, { useEffect } from 'react';
import AOS from 'aos';
import 'aos/dist/aos.css';

const Pricing = () => {
    useEffect(() => {
        AOS.init({ duration: 800, once: true });
    }, []);

    // Data paket harga
    const packages = [
        {
            name: "Silver",
            price: "Rp 600.000",
            duration: "2 Jam",
            desc: "Cocok untuk acara intimate atau ulang tahun skala kecil.",
            features: [
                "Unlimited Foto (Softcopy)",
                "Maksimal cetak 100 lembar",
                "1 Pilihan Frame Custom",
                "Standar Fun Props",
                "Softcopy via QR Code",
                "1 Asisten Standby"
            ],
            isPopular: false,
        },
        {
            name: "Gold",
            price: "Rp 1.000.000",
            duration: "4 Jam",
            desc: "Pilihan favorit untuk acara pernikahan atau perpisahan sekolah.",
            features: [
                "Unlimited Foto (Softcopy)",
                "Maksimal cetak 250 lembar",
                "2 Pilihan Frame Custom",
                "Premium Fun Props",
                "Softcopy via QR Code & G-Drive",
                "2 Asisten Standby",
                "Gratis Lighting Tambahan"
            ],
            isPopular: true, // Ini yang akan kita bikin menonjol
        },
        {
            name: "Platinum",
            price: "Rp 1.500.000",
            duration: "6 Jam",
            desc: "Paket komplit untuk event seharian penuh tanpa khawatir.",
            features: [
                "Unlimited Foto (Softcopy)",
                "Maksimal cetak 400 lembar",
                "3 Pilihan Frame Custom",
                "Premium & Custom Fun Props",
                "Softcopy via QR Code & G-Drive",
                "2 Asisten Standby",
                "Gratis Lighting Tambahan",
                "Gratis Background/Backdrop"
            ],
            isPopular: false,
        }
    ];

    return (
        // Background sedikit berbeda (primary sangat transparan) agar memisah dengan section fitur
        <section id="paket" className="py-24 bg-primary/5">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

                {/* Header Section */}
                <div className="text-center max-w-3xl mx-auto mb-16" data-aos="fade-up">
                    <h2 className="text-secondary font-semibold tracking-wider uppercase text-sm mb-2">Paket Harga</h2>
                    <h3 className="text-3xl md:text-4xl font-bold text-primary mb-4">
                        Pilih Paket Sesuai Acaramu
                    </h3>
                    <p className="text-dark/70 text-lg">
                        Harga transparan, tanpa biaya tersembunyi. Semua paket sudah termasuk biaya transportasi untuk area operasional kami.
                    </p>
                </div>

                {/* Grid Cards Pricing */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-8 items-center">
                    {packages.map((pkg, index) => (
                        <div
                            key={index}
                            data-aos="fade-up"
                            data-aos-delay={index * 150}
                            // Logika CSS: Jika isPopular true, kartu lebih besar, shadow lebih tebal, border primary
                            className={`relative bg-universal rounded-3xl p-8 flex flex-col h-full transition-all duration-300 ${pkg.isPopular
                                ? 'border-2 border-primary shadow-[0_10px_40px_rgba(28,123,127,0.2)]'
                                : 'border border-gray-200 shadow-lg hover:shadow-xl hover:border-primary/30'
                                }`}
                        >
                            {/* Badge "Paling Laris" untuk paket Gold */}
                            {pkg.isPopular && (
                                <div className="absolute top-0 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
                                    <span className="bg-secondary text-dark text-xs font-bold uppercase tracking-widest py-1.5 px-4 rounded-full shadow-md">
                                        Paling Laris
                                    </span>
                                </div>
                            )}

                            {/* Info Paket */}
                            <div className="text-center mb-8">
                                <h4 className="text-xl font-bold text-dark mb-2">{pkg.name}</h4>
                                <p className="text-dark/60 text-sm mb-6 min-h-[40px]">{pkg.desc}</p>
                                <div className="flex justify-center items-baseline mb-2">
                                    <span className="text-4xl font-extrabold text-primary">{pkg.price}</span>
                                </div>
                                <span className="text-secondary font-semibold bg-secondary/10 px-3 py-1 rounded-full text-sm">
                                    Durasi {pkg.duration}
                                </span>
                            </div>

                            {/* List Fitur (Pakai icon checklist hijau tosca/primary) */}
                            <ul className="space-y-4 mb-12">
                                {pkg.features.map((feature, idx) => (
                                    <li key={idx} className="flex items-start">
                                        <svg className="h-6 w-6 text-primary shrink-0 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                                        </svg>
                                        <span className="text-dark/80 text-sm">{feature}</span>
                                    </li>
                                ))}
                            </ul>

                            {/* Tombol CTA */}
                            <a
                                href="#kontak"
                                className={`absolute bottom-4 left-4 right-4 text-center py-3 px-6 rounded-full font-semibold transition-all duration-300 ${pkg.isPopular
                                    ? 'bg-primary text-universal hover:bg-opacity-90 hover:shadow-lg hover:-translate-y-1'
                                    : 'bg-primary/10 text-primary hover:bg-primary hover:text-universal'
                                    }`}
                            >
                                Pilih {pkg.name}
                            </a>
                        </div>
                    ))}
                </div>

            </div>
        </section>
    );
};

export default Pricing;