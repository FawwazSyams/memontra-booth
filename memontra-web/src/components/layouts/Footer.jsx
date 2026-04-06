import React from 'react';
import logo from '../../assets/images/logo-booth.png';

const Footer = () => {
    return (
        // Background primary, teks universal (putih)
        <footer className="bg-primary text-universal pt-16 pb-8">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

                {/* Grid Layout: 1 kolom di HP, 3 kolom di Desktop */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-12 mb-12">

                    {/* Kolom 1: Info Brand */}
                    <div className="flex flex-col space-y-4">
                        <img src={logo} alt="Memontra Logo" className="w-64 h-auto" />
                        <p className="text-universal/80 text-sm leading-relaxed max-w-sm">
                            Menghadirkan senyuman dan mengabadikan momen spesial Anda dengan layanan photobooth berkualitas, cepat, dan profesional.
                        </p>
                    </div>

                    {/* Kolom 2: Quick Links */}
                    <div className="flex flex-col space-y-4">
                        <h3 className="text-lg font-semibold text-secondary">Jelajahi</h3>
                        <ul className="space-y-2 text-sm text-universal/80">
                            <li><a href="#fitur" className="hover:text-secondary transition-colors">Keunggulan Kami</a></li>
                            <li><a href="#paket" className="hover:text-secondary transition-colors">Paket Harga</a></li>
                            <li><a href="#galeri" className="hover:text-secondary transition-colors">Galeri Momen</a></li>
                            <li><a href="#faq" className="hover:text-secondary transition-colors">Tanya Jawab (FAQ)</a></li>
                        </ul>
                    </div>

                    {/* Kolom 3: Kontak & Lokasi */}
                    <div className="flex flex-col space-y-4">
                        <h3 className="text-lg font-semibold text-secondary">Hubungi Kami</h3>
                        <ul className="space-y-3 text-sm text-universal/80">
                            <li className="flex items-start space-x-3">
                                <span className="text-secondary">📍</span>
                                <span>Area Layanan: Bandung Raya & Cimahi</span>
                            </li>
                            <li className="flex items-center space-x-3">
                                <span className="text-secondary">📞</span>
                                <span>+62 812-XXXX-XXXX (WhatsApp)</span>
                            </li>
                            <li className="flex items-center space-x-3">
                                <span className="text-secondary">✉️</span>
                                <span>halo@memontrabooth.com</span>
                            </li>
                        </ul>
                    </div>

                </div>

                {/* Garis Pembatas */}
                <div className="border-t border-universal/20 pt-8 flex flex-col md:flex-row justify-between items-center text-xs text-universal/60">
                    <p className="mb-4 md:mb-0">
                        &copy; {new Date().getFullYear()} Memontra Booth. All rights reserved.
                    </p>
                    <p>
                        Powered by <span className="text-universal font-semibold hover:text-secondary cursor-pointer transition-colors">SyamsDev</span>
                    </p>
                </div>

            </div>
        </footer>
    );
};

export default Footer;